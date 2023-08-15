import 'package:magical_version_bump/src/core/enums/enums.dart';
import 'package:magical_version_bump/src/core/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/core/extensions/extensions.dart';
import 'package:magical_version_bump/src/core/mixins/command_mixins.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_semver/pub_semver.dart';

class HandleModifyCommand
    with
        NormalizeArgs,
        ValidatePreppedArgs,
        HandleFile,
        ValidateVersion,
        ModifyYaml {
  HandleModifyCommand({required this.logger});

  final Logger logger;

  /// Modify the version in pubspec.yaml
  Future<void> handleCommand(List<String> args) async {
    // Command progress
    final prepProgress = logger.progress('Checking arguments');

    // Normalize args & check validity
    final normalizedArgs = normalizeArgs(args);

    final argsWithNoSetters = checkForSetters(normalizedArgs);

    final validated = await validateArgs(
      argsWithNoSetters.args,
      isModify: true,
      userSetPath: argsWithNoSetters.path != null,
      logger: logger,
    );

    if (validated.invalidReason != null) {
      prepProgress.fail(validated.invalidReason!.key);
      throw MagicalException(violation: validated.invalidReason!.value);
    }

    final preppedArgs = prepArgs(validated.args);

    prepProgress.complete('Checked arguments');

    // Read pubspec.yaml file
    final fileData = await readFile(
      requestPath: preppedArgs.requestPath,
      logger: logger,
      setPath: argsWithNoSetters.path,
    );

    var currentVersion = '';

    // Preset any values before validation. This assumes you want keep your old
    // build number and prerelease info
    if (argsWithNoSetters.preset || argsWithNoSetters.presetOnlyVersion) {
      // Parse old version
      Version? oldVersion;

      if (fileData.yamlMap['version'] != null) {
        oldVersion = Version.parse(fileData.yamlMap['version'].toString());
      }

      // Throw error if both 'set-version' and old version are null
      if (argsWithNoSetters.version == null && oldVersion == null) {
        throw MagicalException(
          violation: 'At least one valid version is required.',
        );
      }

      currentVersion = Version.parse(
        argsWithNoSetters.version ?? oldVersion.toString(),
      ).setPreAndBuild(
        updatedPre: argsWithNoSetters.keepPre
            ? (oldVersion!.preRelease.isEmpty
                ? null
                : oldVersion.preRelease.join('.'))
            : argsWithNoSetters.prerelease,
        updatedBuild: argsWithNoSetters.keepBuild
            ? (oldVersion!.build.isEmpty ? null : oldVersion.build.join('.'))
            : argsWithNoSetters.build,
      );
    }

    // Validate version and get correct version
    currentVersion = await validateVersion(
      logger: logger,
      // Use isModify only when preset is false
      isModify:
          !argsWithNoSetters.preset && !argsWithNoSetters.presetOnlyVersion,
      yamlMap: fileData.yamlMap,
      version: currentVersion,
    );

    // Modify the version
    final modProgress = logger.progress(
      preppedArgs.action == 'b' || preppedArgs.action == 'bump'
          ? 'Bumping up version'
          : 'Bumping down version',
    );

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
    if ((!argsWithNoSetters.preset || argsWithNoSetters.presetOnlyVersion) &&
        (argsWithNoSetters.prerelease != null ||
            argsWithNoSetters.build != null)) {
      versionToSave = Version.parse(versionToSave).setPreAndBuild(
        keepPre: argsWithNoSetters.keepPre,
        keepBuild: argsWithNoSetters.keepBuild,
        updatedPre: argsWithNoSetters.prerelease,
        updatedBuild: argsWithNoSetters.build,
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
    );

    /// Show success
    logger.success(
      """Version ${preppedArgs.action == 'b' || preppedArgs.action == 'bump' ? 'bumped up' : 'bumped down'} from $currentVersion to $versionToSave""",
    );
  }
}
