import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

void main() {
  late Logger logger;

  final fileAsMap = {
    'key': 'value',
    'otherKey': [
      'value',
      {'key': 'value'},
    ],
  };

  final keysToFind = (keys: ['key'], orderType: OrderType.loose);
  final valuesToFind = ['value'];
  final pairsToFind = {'key': 'value'};

  setUpAll(() {
    logger = _MockLogger();

    when(() => logger.progress(any())).thenReturn(_MockProgress());
  });

  group('finder manager', () {
    test('finds matches in a single file', () async {
      final manager = FinderManager.fullSetup(
        fileQueue: [fileAsMap],
        aggregator: (
          applyToEachArg: true,
          applyToEachFile: true,
          type: AggregateType.all,
          count: null,
        ),
        logger: logger,
        finderType: FinderType.byValue,
        keysToFind: keysToFind,
        valuesToFind: valuesToFind,
        pairsToFind: pairsToFind,
      );

      await manager.transform();

      final counter = manager.managerCounter;

      // 3 matches will be found in first file
      expect(counter.getCount(0, origin: Origin.custom), 3);
    });

    test('finds matches in multiple files', () async {
      final manager = FinderManager.fullSetup(
        fileQueue: [fileAsMap, fileAsMap], // just add same file twice
        aggregator: (
          applyToEachArg: true,
          applyToEachFile: true,
          type: AggregateType.all,
          count: null,
        ),
        logger: logger,
        finderType: FinderType.byValue,
        keysToFind: keysToFind,
        valuesToFind: valuesToFind,
        pairsToFind: pairsToFind,
      );

      await manager.transform();

      final counter = manager.managerCounter;

      // 7 matches will be found in first file
      expect(counter.getCount(0, origin: Origin.custom), 3);
      expect(counter.getCount(1, origin: Origin.custom), 3);
    });

    test(
      'finds matches for each arg but not each file when count is provided',
      () async {
        final manager = FinderManager.fullSetup(
          fileQueue: [fileAsMap, fileAsMap],
          aggregator: (
            applyToEachArg: true,
            applyToEachFile: false,
            type: AggregateType.count,
            count: 1,
          ),
          logger: logger,
          finderType: FinderType.byValue,
          keysToFind: null,
          valuesToFind: valuesToFind,
          pairsToFind: null,
        );

        await manager.transform();

        final counter = manager.managerCounter;

        // 1 match will be found in first file. Second file ignored
        expect(counter.getCount(0, origin: Origin.custom), 1);
        expect(counter.getCount(1, origin: Origin.custom), 0);
      },
    );

    test('finds matches for each file but not each argument', () async {
      final manager = FinderManager.fullSetup(
        fileQueue: [fileAsMap, fileAsMap],
        aggregator: (
          applyToEachArg: false,
          applyToEachFile: true,
          type: AggregateType.count,
          count: 1,
        ),
        logger: logger,
        finderType: FinderType.byValue,
        keysToFind: null,
        valuesToFind: valuesToFind,
        pairsToFind: null,
      );

      await manager.transform();

      final counter = manager.managerCounter;

      // 1 match will be found in both files
      expect(counter.getCount(0, origin: Origin.custom), 1);
      expect(counter.getCount(1, origin: Origin.custom), 1);
    });

    test(
      'finds matches based on simple count when not applying to each arg/file',
      () async {
        // Exits once count has been reached.
        final fileOne = {'key': 'notValue'};
        final fileTwo = {'key': 'notValue'};
        final fileThree = {'key': 'value'};

        // Will have to check until last file to get count of 1
        final manager = FinderManager.fullSetup(
          fileQueue: [fileOne, fileTwo, fileThree],
          aggregator: (
            applyToEachArg: false,
            applyToEachFile: false,
            type: AggregateType.count,
            count: 1,
          ),
          logger: logger,
          finderType: FinderType.byValue,
          keysToFind: null,
          valuesToFind: valuesToFind,
          pairsToFind: null,
        );

        await manager.transform();

        final counter = manager.managerCounter;

        // 1 match will be found in third file
        expect(counter.getCount(0, origin: Origin.custom), 0);
        expect(counter.getCount(1, origin: Origin.custom), 0);
        expect(counter.getCount(2, origin: Origin.custom), 1);
      },
    );
  });

  group('replacer manager', () {
    test('replaces keys found by Finder Manager', () async {
      final manager = ReplacerManager.defaultSetup(
        commandType: WalkSubCommandType.rename,
        fileQueue: [fileAsMap],
        aggregator: (
          applyToEachArg: true,
          applyToEachFile: true,
          type: AggregateType.all,
          count: null,
        ),
        logger: logger,
        substituteToMatchers: {
          'replacedKey': ['key'],
        },
      );

      await manager.transform();

      final modifiedFile = {
        'replacedKey': 'value',
        'otherKey': [
          'value',
          {'replacedKey': 'value'},
        ],
      };

      final counter = manager.managerCounter;

      // Will replace two matches
      expect(counter.getCount(0, origin: Origin.custom), 2);
      expect(manager.modifiedFiles?.first.modifiedFile, equals(modifiedFile));
    });

    test('replaces values found by Finder Manager', () async {
      final manager = ReplacerManager.defaultSetup(
        commandType: WalkSubCommandType.replace,
        fileQueue: [fileAsMap],
        aggregator: (
          applyToEachArg: true,
          applyToEachFile: true,
          type: AggregateType.all,
          count: null,
        ),
        logger: logger,
        substituteToMatchers: {
          'replacedValue': ['value'],
        },
      );

      await manager.transform();

      final modifiedFile = {
        'key': 'replacedValue',
        'otherKey': [
          'replacedValue',
          {'key': 'replacedValue'},
        ],
      };

      final counter = manager.managerCounter;

      // Will replace 3 matches
      expect(counter.getCount(0, origin: Origin.custom), 3);
      expect(manager.modifiedFiles?.first.modifiedFile, equals(modifiedFile));
    });
  });
}
