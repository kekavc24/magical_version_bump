import 'package:magical_version_bump/src/core/enums/enums.dart';
import 'package:magical_version_bump/src/core/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/core/extensions/extensions.dart';
import 'package:magical_version_bump/src/core/mixins/command_mixins.dart';
import 'package:magical_version_bump/src/utils/arg_sanitizers/arg_sanitizer.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_semver/pub_semver.dart';

class HandleModifyCommand with HandleFile, ValidateVersion, ModifyYaml {
  HandleModifyCommand({required this.logger});

  final Logger logger;

  /// Modify the version in pubspec.yaml
  Future<void> handleCommand(List<String> args) async {
    // Command progress
    final prepProgress = logger.progress('Checking arguments');

    final sanitizer = ModifyArgumentSanitizer();

    // Initial sanitization
    final sanitizedArgs = sanitizer.sanitizeArgs(args);

    // Validate args
    final validatedArgs = sanitizer.customValidate(sanitizedArgs.args);

    if (!validatedArgs.isValid) {
      prepProgress.fail(validatedArgs.reason!.key);
      throw MagicalException(violation: validatedArgs.reason!.value);
    }

    // Final sanitization to desired format
    final preppedArgs = sanitizer.prepArgs(sanitizedArgs.args);

    prepProgress.complete('Checked arguments');

    // Read pubspec.yaml file
    final fileData = await readFile(
      logger: logger,
      requestPath: sanitizedArgs.requestPath,
      setPath: sanitizedArgs.path,
    );

    var currentVersion = '';

    // Preset any values before validating the version. When `--preset` flag is
    // used or `--set-version` option
    if (sanitizedArgs.preset || sanitizedArgs.presetOnlyVersion) {
      // Parse old version
      Version? oldVersion;

      if (fileData.yamlMap['version'] != null) {
        oldVersion = Version.parse(fileData.yamlMap['version'].toString());
      }

      // Throw error if both 'set-version' and old version are null
      if (sanitizedArgs.version == null && oldVersion == null) {
        throw MagicalException(
          violation: 'At least one valid version is required.',
        );
      }

      currentVersion = Version.parse(
        sanitizedArgs.version ?? oldVersion.toString(),
      ).setPreAndBuild(
        updatedPre: sanitizedArgs.keepPre
            ? (oldVersion!.preRelease.isEmpty
                ? null
                : oldVersion.preRelease.join('.'))
            : sanitizedArgs.prerelease,
        updatedBuild: sanitizedArgs.keepBuild
            ? (oldVersion!.build.isEmpty ? null : oldVersion.build.join('.'))
            : sanitizedArgs.build,
      );
    }

    // Validate version and get correct version if invalid. Only use the local
    // version if the version was never preset
    currentVersion = await validateVersion(
      logger: logger,
      useYamlVersion: !sanitizedArgs.preset && !sanitizedArgs.presetOnlyVersion,
      yamlMap: fileData.yamlMap,
      version: currentVersion,
    );

    // Modify the version
    final modProgress = logger.progress(
      preppedArgs.action == 'b' || preppedArgs.action == 'bump'
          ? 'Bumping up version'
          : 'Bumping down version',
    );

    // Get the target with highest weight in relative strategy
    final modifiedVersion = await dynamicBump(
      currentVersion,
      action: preppedArgs.action,
      versionTargets: preppedArgs.strategy == ModifyStrategy.absolute
          ? preppedArgs.versionTargets
          : preppedArgs.versionTargets.getRelative(),
      strategy: preppedArgs.strategy,
    );

    // If build failed silently, warn user
    if (modifiedVersion.buildBumpFailed) {
      logger.warn('Your custom build could not be modified');
    }

    var versionToSave = modifiedVersion.version;

    // If preset is false, but user passed in prerelease & build info.
    // Update it.
    if ((!sanitizedArgs.preset || sanitizedArgs.presetOnlyVersion) &&
        (sanitizedArgs.prerelease != null || sanitizedArgs.build != null)) {
      versionToSave = Version.parse(versionToSave).setPreAndBuild(
        keepPre: sanitizedArgs.keepPre,
        keepBuild: sanitizedArgs.keepBuild,
        updatedPre: sanitizedArgs.prerelease,
        updatedBuild: sanitizedArgs.build,
      );
    }

    final modifiedFile = await editYamlFile(
      fileData.file,
      'version',
      versionToSave,
    );

    modProgress.complete('Modified version');

    /// Save file changes
    await saveFile(
      data: modifiedFile,
      path: fileData.path,
      logger: logger,
      type: fileData.type,
    );

    /// Show success
    logger.success(
      """Version ${preppedArgs.action == 'b' || preppedArgs.action == 'bump' ? 'bumped up' : 'bumped down'} from $currentVersion to $versionToSave""",
    );
  }
}
