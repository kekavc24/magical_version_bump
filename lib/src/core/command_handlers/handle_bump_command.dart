part of 'command_handlers.dart';

final class HandleBumpCommand extends CommandHandler {
  HandleBumpCommand({required super.logger});

  /// Modify the version in pubspec.yaml
  @override
  Future<void> handleCommand(ArgResults? argResults) async {
    // Command progress
    final prepProgress = logger.progress('Checking arguments');

    final sanitizer = BumpArgumentsChecker(argResults: argResults);

    // Validate args
    final validatedArgs = sanitizer.validateArgs();

    if (!validatedArgs.isValid) {
      prepProgress.fail(validatedArgs.reason!.key);
      throw MagicalException(violation: validatedArgs.reason!.value);
    }

    // Required information to bump version
    final preppedArgs = sanitizer.prepArgs();
    final pathInfo = argResults!.pathInfo;
    final versionModifiers = preppedArgs.modifiers;

    prepProgress.complete('Checked arguments');

    // Read pubspec.yaml file
    final fileData = await readFile(
      requestPath: pathInfo.requestPath,
      logger: logger,
      setPath: pathInfo.path,
    );

    var currentVersion = '';

    // Preset any values before validating the version. When `--preset` flag is
    // used or `--set-version` option
    if (versionModifiers.presetType == PresetType.all ||
        versionModifiers.presetType == PresetType.version) {
      Version? oldVersion;

      if (fileData.version != null) {
        oldVersion = Version.parse(fileData.version!);
      }

      /// Throw error if both `set-version` and [oldVersion] are null
      ///
      if (versionModifiers.version == null && oldVersion == null) {
        throw MagicalException(
          violation: 'At least one valid version is required.',
        );
      }

      /// Fallback to old version if version from modifiers is null.
      /// Since `set-prerelease` or `set-build` in `preset` may be used but not
      /// `set-version`
      ///
      currentVersion = Version.parse(
        versionModifiers.version ?? fileData.version!,
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

    /// Validate version and get correct version if invalid. Only use the local
    /// version if the version was never preset using `set-version`
    ///
    /// When preset, the [currentVersion] will not be empty.
    currentVersion = await validateVersion(
      versionModifiers.presetType == PresetType.none
          ? fileData.version
          : currentVersion,
      logger: logger,
    );

    // Modify the version
    final modProgress = logger.progress('Bumping up version');

    // Get the target with highest weight in relative strategy
    final modifiedVersion = await dynamicBump(
      currentVersion,
      versionTargets: preppedArgs.targets,
      strategy: versionModifiers.strategy,
    );

    // If build failed silently, warn user
    if (modifiedVersion.buildHadIssues) {
      logger.warn('Your build number had issues');
    }

    var versionToSave = modifiedVersion.version;

    // If preset is false, but user passed in prerelease & build info.
    // Update it.
    if ((versionModifiers.presetType == PresetType.none ||
            versionModifiers.presetType == PresetType.version) &&
        (versionModifiers.prerelease != null ||
            versionModifiers.build != null)) {
      versionToSave = Version.parse(versionToSave).setPreAndBuild(
        keepPre: versionModifiers.keepPre,
        keepBuild: versionModifiers.keepBuild,
        updatedPre: versionModifiers.prerelease,
        updatedBuild: versionModifiers.build,
      );
    }

    final modifiedFile = await updateYamlFile(
      fileData.file,
      dictionary: (append: false, rootKeys: ['version'], data: versionToSave),
    );

    modProgress.complete('Modified version');

    /// Save file changes
    await saveFile(
      file: modifiedFile,
      path: fileData.path,
      logger: logger,
      type: fileData.fileType,
    );

    /// Show success
    logger.success(
      'Version bumped up from $currentVersion to $versionToSave',
    );
  }
}
