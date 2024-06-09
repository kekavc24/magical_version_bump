part of '../command_handlers.dart';

final class HandleFindCommand extends HandleWalkCommand {
  HandleFindCommand({
    required super.logger,
  }) : super(subCommandType: WalkSubCommandType.find);

  @override
  void _setUpManager(List<Map<dynamic, dynamic>> fileQueue) {
    // Obtain prepped args from checker
    final checker = _getChecker<FindArgumentsNormalizer>();
    final (aggregator, keys, values, pairs) = checker.prepArgs();

    _manager = FinderManager.fullSetup(
      fileQueue: fileQueue,
      aggregator: aggregator,
      logger: logger,
      finderType: FinderType.byValue,
      keysToFind: keys,
      valuesToFind: values,
      pairsToFind: pairs,
    );
  }

  @override
  void _setUpArgChecker(ArgResults? argResults) {
    _argumentsNormalizer = FindArgumentsNormalizer(argResults: argResults);
  }

  @override
  (Counter<int, int>, Counter<int, int>?) _getCounters() {
    final manager = _manager as FinderManager;

    return (manager.managerCounter, null);
  }
}
