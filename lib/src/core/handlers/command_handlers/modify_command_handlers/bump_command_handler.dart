part of '../command_handlers.dart';

final class HandleBumpCommand extends CommandHandler {
  HandleBumpCommand({required super.logger});

  /// Setup our bump arguments
  @override
  void _setUpArgChecker(ArgResults? argResults) {
    super._argumentsNormalizer = BumpArgumentsNormalizer(
      argResults: argResults,
    );
  }

  /// Modify the version in pubspec.yaml
  @override
  Future<void> _coreCommandHandler(ArgResults? argResults) async {
    final checker = _getChecker<BumpArgumentsNormalizer>();

    // Required information to bump version
    final (versionModifiers, targets) = checker.prepArgs();

    // Read pubspec.yaml file
    final fileOuput = await _fileHandler.readFile();

    final localVersion = fileOuput.fileAsMap['version'] as String?;

    /// Preset any values before validating the version. When `--preset` flag
    /// is used or `--set-version` option
    final currentVersion = addPresets(
      localVersion ?? '',
      modifiers: versionModifiers,
    );

    /// Validate version and get correct version if invalid.
    final validatedVersion = await validateVersion(
      currentVersion,
      logger: logger,
    );

    // Bump the version
    final modProgress = logger.progress('Bumping up version');

    final modifiedVersion = bumpVersion(
      validatedVersion,
      versionTargets: targets,
      strategy: versionModifiers.strategy,
    );

    // If build failed silently, warn user
    if (modifiedVersion.buildHadIssues) {
      logger.warn('Your build number had issues');
    }

    // Add final touches before updating yaml file
    final versionToSave = appendPreAndBuild(
      modifiedVersion.version,
      modifiers: versionModifiers,
    );

    final modifiedFile = await updateYamlFile(
      fileOuput,
      dictionary: (
        updateMode: UpdateMode.overwrite,
        rootKeys: ['version'],
        data: versionToSave,
      ),
    );

    modProgress.complete('Modified version');

    // Save file changes
    await _fileHandler.saveFile(modifiedFile);

    // Show success
    logger.success(
      'Version bumped up from $currentVersion to $versionToSave',
    );
  }
}
