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
    final fileOuput = await _fileHandler.readFile();

    // Set up re-usable file
    var editedFile = fileOuput.file;

    final changeProgress = logger.progress('Updating nodes');

    if (preppedArgs.dictionaries.isNotEmpty) {
      ///
      /// Loop all entries. The first entry will use file read fresh from disk
      /// while successive entries will use the previously modified file
      for (final (index, dictionary) in preppedArgs.dictionaries.indexed) {
        editedFile = index == 0
            ? await updateYamlFile(fileOuput, dictionary: dictionary)
            : await updateYamlFile(
                (
                  file: editedFile,
                  fileAsMap: _fileHandler.convertToMap(editedFile)
                ),
                dictionary: dictionary,
              );
      }
    }

    /// Incase `set-version` was used instead of using the `dictionary` syntax,
    /// update it
    if (versionModifiers.presetType != PresetType.none) {
      final localVersion = fileOuput.fileAsMap['version'] as String?;

      final version = MagicalSEMVER.addPresets(
        localVersion ?? '',
        modifiers: versionModifiers,
      );

      editedFile = await updateYamlFile(
        (file: editedFile, fileAsMap: _fileHandler.convertToMap(editedFile)),
        dictionary: (
          updateMode: UpdateMode.overwrite,
          rootKeys: ['version'],
          data: version,
        ),
      );
    }

    changeProgress.complete('Changed all nodes');

    /// Save file changes
    await _fileHandler.saveFile(editedFile);

    /// Show success
    logger.success('Updated your yaml file!');
  }
}
