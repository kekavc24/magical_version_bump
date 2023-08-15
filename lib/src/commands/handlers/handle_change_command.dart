import 'package:magical_version_bump/src/core/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/core/extensions/extensions.dart';
import 'package:magical_version_bump/src/core/mixins/command_mixins.dart';
import 'package:magical_version_bump/src/utils/arg_sanitizers/arg_sanitizer.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_semver/pub_semver.dart';

class HandleChangeCommand with HandleFile, ValidateVersion, ModifyYaml {
  HandleChangeCommand({required this.logger});

  final Logger logger;

  /// Change specified node in yaml file
  Future<void> handleCommand(List<String> args) async {
    // Start progress
    final prepProgress = logger.progress('Checking arguments');

    final sanitizer = ChangeArgumentSanitizer();

    // Sanitize args
    final sanitizedArgs = sanitizer.sanitizeArgs(args);

    // Get desired format
    final preppedArgs = sanitizer.prepArgs(sanitizedArgs.args);

    // Actual option are keys
    final argKeys = preppedArgs.keys.toList();

    // Validate all options.
    final validatedArgs = sanitizer.validateArgs(argKeys);

    if (!validatedArgs.isValid) {
      prepProgress.fail(validatedArgs.reason!.key);
      throw MagicalException(violation: validatedArgs.reason!.value);
    }

    prepProgress.complete('Checked arguments');

    // Read pubspec.yaml file
    final fileData = await readFile(
      logger: logger,
      requestPath: sanitizedArgs.requestPath,
      setPath: sanitizedArgs.path,
    );

    var version = '';

    // If user wants version change, check if valid
    if (argKeys.contains('yaml-version') ||
        sanitizedArgs.prerelease != null ||
        sanitizedArgs.build != null ||
        sanitizedArgs.version != null) {
      logger.warn('Version flag detected. Must verify version is valid');

      if (argKeys.contains('yaml-version')) {
        logger
          ..warn(
            """Consider using 'set-version'. 'yaml-version' will be deprecated soon""",
          )
          ..warn(
            """'set-version' will overwrite 'yaml-version' if both are used""",
          );
      }

      // Check version that user want to change to or the current version
      version = await validateVersion(
        logger: logger,
        useYamlVersion: false,
        version: sanitizedArgs.version ??
            preppedArgs['yaml-version'] ??
            fileData.yamlMap['version'] as String?,
      );
    }

    // Set up re-usable file
    var editedFile = fileData.file;

    final changeProgress = logger.progress('Changing yaml nodes');

    final entries = preppedArgs.entries;

    for (final node in entries) {
      editedFile = await editYamlFile(
        editedFile,
        node.key == 'yaml-version' ? 'version' : node.key,
        node.key == 'yaml-version' ? version : node.value,
      );
    }

    // Update any `set-prerelease` or `set-build` after version
    if (sanitizedArgs.build != null ||
        sanitizedArgs.prerelease != null ||
        sanitizedArgs.version != null) {
      final updatedVersion = Version.parse(
        sanitizedArgs.version ?? version,
      ).setPreAndBuild(
        keepPre: sanitizedArgs.keepPre,
        keepBuild: sanitizedArgs.keepBuild,
        updatedPre: sanitizedArgs.prerelease,
        updatedBuild: sanitizedArgs.build,
      );

      editedFile = await editYamlFile(editedFile, 'version', updatedVersion);
    }

    changeProgress.complete('Changed all nodes');

    /// Save file changes
    await saveFile(
      data: editedFile,
      path: fileData.path,
      logger: logger,
      type: fileData.type,
    );

    /// Show success
    logger.success('Updated your yaml file!');
  }
}
