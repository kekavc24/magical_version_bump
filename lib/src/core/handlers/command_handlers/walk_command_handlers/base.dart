part of '../command_handlers.dart';

abstract base class HandleWalkCommand extends CommandHandler {
  HandleWalkCommand({
    required super.logger,
    required WalkSubCommandType subCommandType,
  }) : _subCommandType = subCommandType;

  /// Indicate the specific subcommand being executed
  final WalkSubCommandType _subCommandType;

  /// A manager that handles internal "map-walk" functionalities
  late TransformerManager<dynamic> _manager;

  /// Set up [TransformerManager] to handle recursions
  ///
  /// Internally, the [TransformerManager] sets up a `Formatter`.
  ///
  /// Logic includes any prepped args as each command is set differently
  void _setUpManager(List<Map<dynamic, dynamic>> fileQueue);

  @override
  Future<void> _coreCommandHandler(ArgResults? argResults) async {
    // Read all files added to be used
    final files = await _fileHandler.readAll(multiple: true);

    _setUpManager(files.map((e) => e.fileAsMap).toList());

    await _manager.transform();

    final isReplaceMode = !_subCommandType.isFinder;
    final (finderCounter, replacerCounter) = _getCounters();

    // Save changes as replace mode modifies them
    if (isReplaceMode) {
      final saveProgress = logger.progress('Saving changes');

      final modifiedFiles = (_manager as ReplacerManager).modifiedFiles;

      if (modifiedFiles == null || modifiedFiles.isEmpty) {
        saveProgress.complete('No changes made');
      } else {
        // Save changes
        for (final modifiedFile in modifiedFiles) {
          await _fileHandler.saveFile(
            modifiedFile.modifiedFile.toString(),
            index: modifiedFile.fileIndex,
            showProgress: false,
          );
        }
        saveProgress.complete('Saved changes');
      }
    }

    final output = _manager.formatter.format(
      isReplaceMode: isReplaceMode,
      fileNames: _fileHandler.filePaths,
      finderFileCounter: finderCounter,
      replacerFileCounter: replacerCounter,
    );

    logger.info(output);
  }

  (
    Counter<int, int> finderFileCounter,
    Counter<int, int>? replacerFileCounter,
  ) _getCounters();
}
