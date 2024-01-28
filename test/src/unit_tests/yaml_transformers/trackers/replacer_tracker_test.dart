import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/tracker.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:test/test.dart';

typedef _MockReplacerTracker = ReplacerTracker;

void main() {
  final tracker = _MockReplacerTracker();
  final defaultMatch = MatchedNodeData.fromFinder(
    nodeData: NodeData.stringSkeleton(
      path: const ['root'],
      key: 'key',
      value: 'value',
    ),
    matchedKeys: const ['key'],
    matchedValue: '',
    matchedPairs: const {},
  );

  group('rename tracker', () {
    test('adds all matches while renaming keys', () {
      // Replacer tracker uses a file index as a cursor. Use same match
      final outputs = <FindManagerOutput>[
        (currentFile: 0, data: defaultMatch),
        (currentFile: 1, data: defaultMatch),
      ];

      tracker.addAll(outputs);

      // Path to last renameable key is 'root/key'
      const basicKey = TrackerKey<String>.fromValue(
        'root/key',
        Origin.custom,
      );

      /// File with index [0] will be pushed to history with path upto
      /// last renameable key as its key.
      expect(tracker.getFromHistory(0), equals({basicKey: defaultMatch}));

      /// Curent state will have state of last index
      expect(tracker.trackerState, equals({basicKey: defaultMatch}));

      /// All matches linked to each file
      final linkedMatches = tracker.getMatches();

      expect(linkedMatches.map((e) => e.fileNumber), equals([0, 1]));
      expect(
        linkedMatches.map((e) => e.matches).flattened.toSet(),
        {defaultMatch},
      );
    });

    test('never adds duplicate paths for keys to be renamed from same file',
        () {
      // Match nested further along same path as default match
      final anotherMatch = MatchedNodeData.fromFinder(
        nodeData: NodeData.stringSkeleton(
          path: const ['root', 'key'],
          key: 'anotherKey',
          value: 'value',
        ),
        matchedKeys: const ['key'],
        matchedValue: '',
        matchedPairs: const {},
      );

      final outputs = <FindManagerOutput>[
        (currentFile: 0, data: defaultMatch),
        (currentFile: 0, data: anotherMatch),
      ];

      tracker.addAll(outputs);

      expect(
        tracker.getMatches().map((e) => e.matches).flattened,
        equals([defaultMatch]),
      );
    });

    test(
      'adds paths if last renameable key further than previously added match',
      () {
        // Match nested further along same path as default match
        final anotherMatch = MatchedNodeData.fromFinder(
          nodeData: NodeData.stringSkeleton(
            path: const ['root', 'key'],
            key: 'anotherKey',
            value: 'value',
          ),
          matchedKeys: const ['key', 'anotherKey'],
          matchedValue: '',
          matchedPairs: const {},
        );

        final outputs = <FindManagerOutput>[
          (currentFile: 0, data: defaultMatch),
          (currentFile: 0, data: anotherMatch),
        ];

        tracker.addAll(outputs);

        expect(
          tracker.getMatches().map((e) => e.matches).flattened,
          equals([defaultMatch, anotherMatch]),
        );
      },
    );
  });

  tearDown(() {
    tracker.history.clear();
    tracker.trackerState.clear();
  });
}
