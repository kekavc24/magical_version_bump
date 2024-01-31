import 'package:magical_version_bump/src/core/yaml_transformers/formatter/formatter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/managers/finder_manager/finder_formatter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/managers/replacer_manager/replacer_formatter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/tracker.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:test/test.dart';

void main() {
  group('finder formatter', () {
    final finderFormatter = FinderFormatter();

    final match = MatchedNodeData.fromFinder(
      nodeData: NodeData.stringSkeleton(
        path: const ['root'],
        key: 'key',
        value: 'value',
      ),
      matchedKeys: const ['key'],
      matchedValue: 'value',
      matchedPairs: const {'root': 'key'},
    );

    final path = TrackerKey(
      key: [
        'root',
        'key',
        'value',
      ].map((e) => matchColor.wrap(e)).join('/'),
      origin: Origin.custom,
    );

    const keys = [
      TrackerKey(key: 'value', origin: Origin.value),
      TrackerKey(key: 'key', origin: Origin.key),
      DualTrackerKey(key: 'root', otherKey: 'key'),
    ];

    test('extracts keys and path from MatchedNodeData', () {
      final extractedInfo = finderFormatter.extractFrom(match);

      expect(extractedInfo.keys, equals(keys));
      expect(extractedInfo.path, equals(path));
    });

    test('extracts and adds all inputs for each file index', () {
      finderFormatter.addAll([
        (0, [match]),
        (1, [match]),
      ]);

      // Force a reset so all values are in history
      finderFormatter.tracker.reset(cursor: 1); // Last index is the cursor

      final defaultTrackerState =
          <TrackerKey<String>, List<TrackerKey<String>>>{}..addEntries(
              keys.map((e) => MapEntry(e, [path])),
            );

      expect(
        finderFormatter.tracker.history,
        equals({
          0: defaultTrackerState,
          1: defaultTrackerState,
        }),
      );
    });
  });

  group('replacer formatter', () {
    final replacerFormatter = ReplacerFormatter();

    final replacerInput = (
      mapping: {'key': 'updatedKey'},
      oldPath: 'key/value',
      origin: Origin.key
    );

    const keys = [
      TrackerKey(key: 'key', origin: Origin.key),
    ];

    final pathInfo = DualTrackerKey(
      key: "${replacedColor.wrap('key')}/value",
      otherKey: "${matchColor.wrap('updatedKey')}/value",
    );

    test('extracts keys and path from ReplacerManagerOutput', () {
      final extractedInfo = replacerFormatter.extractFrom(replacerInput);

      expect(extractedInfo.keys, equals(keys));
      expect(extractedInfo.path, equals(pathInfo));
    });

    test('extracts and adds all inputs for each file index', () {
      replacerFormatter.addAll([
        (0, [replacerInput]),
        (1, [replacerInput]),
      ]);

      // Force a reset so all values are in history
      replacerFormatter.tracker.reset(cursor: 1); // Last index is the cursor

      final defaultTrackerState = {
        keys.first: [pathInfo],
      };

      expect(
        replacerFormatter.tracker.history,
        equals({
          0: defaultTrackerState,
          1: defaultTrackerState,
        }),
      );
    });
  });
}
