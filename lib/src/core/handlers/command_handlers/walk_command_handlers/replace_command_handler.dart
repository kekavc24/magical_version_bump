part of '../command_handlers.dart';

final class HandleReplaceCommand extends HandleWalkCommand {
  HandleReplaceCommand({
    required super.logger,
    required super.subCommandType,
  });

  @override
  void _setUpManager(List<Map<dynamic, dynamic>> fileQueue) {
    // Obtain prepped args from checker
    final checker = _getChecker<ReplacerArgumentsNormalizer>();
    final (aggregator, substituteToMatchers) = checker.prepArgs();

    _manager = ReplacerManager.defaultSetup(
      commandType: _subCommandType,
      fileQueue: fileQueue,
      aggregator: aggregator,
      logger: logger,
      substituteToMatchers: substituteToMatchers,
    );
  }

  @override
  void _setUpArgChecker(ArgResults? argResults) {
    _argumentsNormalizer = ReplacerArgumentsNormalizer(
      argResults: argResults,
      isRename: _subCommandType == WalkSubCommandType.rename,
    );
  }

  @override
  (Counter<int, int>, Counter<int, int>?) _getCounters() {
    final manager = _manager as ReplacerManager;

    return (
      manager.finderManagerCounter,
      manager.managerCounter,
    );
  }
}
