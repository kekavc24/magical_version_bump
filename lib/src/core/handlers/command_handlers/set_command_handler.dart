part of 'command_handlers.dart';

class HandleSetCommand extends CommandHandler {
  HandleSetCommand({required super.logger});

  @override
  void _setUpArgChecker(ArgResults? argResults) {
    super._argumentsChecker = SetArgumentsChecker(argResults: argResults);
  }

  /// Change specified node in yaml file
  @override
  Future<void> _coreCommandHandler(ArgResults? argResults) async {
    final checker = _getChecker<SetArgumentsChecker>();

    final preppedArgs = checker.prepArgs();
    final versionModifiers = preppedArgs.modifiers;

    // Read pubspec.yaml file
    final fileData = await _fileHandler.readFile();

    // Set up re-usable file
    var editedFile = json.encode(fileData);

    final changeProgress = logger.progress('Updating nodes');

    if (preppedArgs.dictionaries.isNotEmpty) {
      for (final dictionary in preppedArgs.dictionaries) {
        editedFile = await updateYamlFile(editedFile, dictionary: dictionary);
      }
    }

    /// Incase `set-version` was used instead of using the `dictionary` syntax,
    /// update it
    if (versionModifiers.presetType != PresetType.none) {
      final localVersion = fileData['version'] as String?;

      final version = MagicalSEMVER.addPresets(
        localVersion ?? '',
        modifiers: versionModifiers,
      );

      editedFile = await updateYamlFile(
        editedFile,
        dictionary: (
          append: false,
          rootKeys: ['version'],
          data: version,
        ),
      );
    }

    changeProgress.complete('Changed all nodes');

    /// Save file changes
    await _fileHandler.saveFile(loadYaml(editedFile) as YamlMap);

    /// Show success
    logger.success('Updated your yaml file!');
  }
}
