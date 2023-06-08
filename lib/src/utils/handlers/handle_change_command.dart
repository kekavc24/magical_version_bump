import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_semver/pub_semver.dart';

typedef ChangeableNodes = Iterable<MapEntry<String, String>>;

class HandleChangeCommand
    with
        HandleFile,
        NormalizeArgs,
        ValidatePreppedArgs,
        ValidateVersion,
        ModifyYaml {
  HandleChangeCommand({required this.logger});

  final Logger logger;

  /// Change specified node in yaml file
  Future<void> handleCommand(List<String> args) async {
    final prepProgress = logger.progress('Checking arguments');

    // Normalize args & check validity
    final normalizedArgs = normalizeArgs(args);

    final argsWithoutSetters = checkForSetters(normalizedArgs);

    final preppedArgs = getArgAndValues(argsWithoutSetters.args);

    final validatedArgs = await validateArgs(
      preppedArgs.keys.toList(),
      userSetPath: argsWithoutSetters.path != null,
      logger: logger,
    );

    if (validatedArgs.invalidReason != null) {
      prepProgress.fail(validatedArgs.invalidReason!.key);
      throw MagicalException(violation: validatedArgs.invalidReason!.value);
    }

    prepProgress.complete('Checked arguments');

    // Read pubspec.yaml file
    final fileData = await readFile(
      requestPath: validatedArgs.args.contains('with-path'),
      logger: logger,
      setPath: argsWithoutSetters.path,
    );

    var version = '';

    // If user wants version change, check if valid
    if (validatedArgs.args.contains('yaml-version') ||
        argsWithoutSetters.prerelease != null ||
        argsWithoutSetters.build != null ||
        argsWithoutSetters.version != null) {
      logger.warn('Version flag detected. Must verify version is valid');

      if (validatedArgs.args.contains('yaml-version')) {
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
        version: argsWithoutSetters.version ??
            preppedArgs['yaml-version'] ??
            fileData.yamlMap['version'] as String?,
      );
    }

    // Set up re-usable file
    var editedFile = fileData.file;

    final changeProgress = logger.progress('Changing yaml nodes');

    // Loop all entries and match with validated args
    final validMap = validatedArgs.args.fold(
      <String, String>{},
      (previousValue, element) {
        previousValue.addAll({element: preppedArgs[element] ?? ''});
        return previousValue;
      },
    );

    final entries = validMap.entries.where(
      (element) => element.key != 'with-path',
    );

    for (final node in entries) {
      editedFile = await editYamlFile(
        editedFile,
        node.key == 'yaml-version' ? 'version' : node.key,
        node.key == 'yaml-version' ? version : node.value,
      );
    }

    // Update any 'set-prerelease' or 'set-build' options after 'yaml-version'
    if (argsWithoutSetters.build != null ||
        argsWithoutSetters.prerelease != null ||
        argsWithoutSetters.version != null) {
      final updatedVersion = Version.parse(
        argsWithoutSetters.version ?? version,
      ).setPreAndBuild(
        keepPre: argsWithoutSetters.keepPre,
        keepBuild: argsWithoutSetters.keepBuild,
        updatedPre: argsWithoutSetters.prerelease,
        updatedBuild: argsWithoutSetters.build,
      );

      editedFile = await editYamlFile(editedFile, 'version', updatedVersion);
    }

    changeProgress.complete('Changed all nodes');

    /// Save file changes
    await saveFile(data: editedFile, path: fileData.path, logger: logger);

    /// Show success
    logger.success('Updated your yaml file!');
  }
}
