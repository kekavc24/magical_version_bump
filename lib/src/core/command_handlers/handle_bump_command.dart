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

    /// Preset any values before validating the version. When `--preset` flag
    /// is used or `--set-version` option
    final currentVersion = MagicalSEMVER.addPresets(
      fileData.version ?? '',
      modifiers: versionModifiers,
    );

    /// Validate version and get correct version if invalid.
    final validatedVersion = await validateVersion(
      currentVersion,
      logger: logger,
    );

    // Bump the version
    final modProgress = logger.progress('Bumping up version');

    final modifiedVersion = MagicalSEMVER.bumpVersion(
      validatedVersion,
      versionTargets: preppedArgs.targets,
      strategy: versionModifiers.strategy,
    );

    // If build failed silently, warn user
    if (modifiedVersion.buildHadIssues) {
      logger.warn('Your build number had issues');
    }

    // Add final touches before updating yaml file
    final versionToSave = MagicalSEMVER.appendPreAndBuild(
      modifiedVersion.version,
      modifiers: versionModifiers,
    );

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
