part of 'command_handlers.dart';

final class HandleBumpCommand extends CommandHandler {
  HandleBumpCommand({required super.logger});

  /// Modify the version in pubspec.yaml
  @override
  Future<void> handleCommand(ArgResults? argResults) async {
    // Command progress
    final prepProgress = logger.progress('Checking arguments');

    final sanitizer = BumpArgumentSanitizer(argResults: argResults);

    // Validate args
    final validatedArgs = sanitizer.customValidate();

    if (!validatedArgs.isValid) {
      prepProgress.fail(validatedArgs.reason!.key);
      throw MagicalException(violation: validatedArgs.reason!.value);
    }

    // Final sanitization to desired format
    final preppedArgs = sanitizer.prepArgs();
    final checkedPath = sanitizer.pathInfo;
    final versionModifiers = sanitizer.modifiers(checkPreset: true);

    prepProgress.complete('Checked arguments');

    // Read pubspec.yaml file
    final fileData = await readFile(
      requestPath: checkedPath.requestPath,
      logger: logger,
      setPath: checkedPath.path,
    );

    var currentVersion = '';

    // Preset any values before validating the version. When `--preset` flag is
    // used or `--set-version` option
    if (versionModifiers.preset || versionModifiers.presetOnlyVersion) {
      // Parse old version
      Version? oldVersion;

      if (fileData.yamlMap['version'] != null) {
        oldVersion = Version.parse(fileData.yamlMap['version'].toString());
      }

      // Throw error if both 'set-version' and old version are null
      if (versionModifiers.version == null && oldVersion == null) {
        throw MagicalException(
          violation: 'At least one valid version is required.',
        );
      }

      currentVersion = Version.parse(
        versionModifiers.version ?? oldVersion.toString(),
      ).setPreAndBuild(
        updatedPre: versionModifiers.keepPre
            ? (oldVersion!.preRelease.isEmpty
                ? null
                : oldVersion.preRelease.join('.'))
            : versionModifiers.prerelease,
        updatedBuild: versionModifiers.keepBuild
            ? (oldVersion!.build.isEmpty ? null : oldVersion.build.join('.'))
            : versionModifiers.build,
      );
    }

    // Validate version and get correct version if invalid. Only use the local
    // version if the version was never preset
    currentVersion = await validateVersion(
      logger: logger,
      useYamlVersion:
          !versionModifiers.preset && !versionModifiers.presetOnlyVersion,
      yamlMap: fileData.yamlMap,
      version: currentVersion,
    );

    // Modify the version
    final modProgress = logger.progress('Bumping up version');

    // Get the target with highest weight in relative strategy
    final modifiedVersion = await dynamicBump(
      currentVersion,
      versionTargets: preppedArgs.targets,
      strategy: preppedArgs.strategy,
    );

    // If build failed silently, warn user
    if (modifiedVersion.buildBumpFailed) {
      logger.warn('Your custom build could not be modified');
    }

    var versionToSave = modifiedVersion.version;

    // If preset is false, but user passed in prerelease & build info.
    // Update it.
    if ((!versionModifiers.preset || versionModifiers.presetOnlyVersion) &&
        (versionModifiers.prerelease != null ||
            versionModifiers.build != null)) {
      versionToSave = Version.parse(versionToSave).setPreAndBuild(
        keepPre: versionModifiers.keepPre,
        keepBuild: versionModifiers.keepBuild,
        updatedPre: versionModifiers.prerelease,
        updatedBuild: versionModifiers.build,
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
      'Version bumped up from $currentVersion to $versionToSave',
    );
  }
}
