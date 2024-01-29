import 'package:magical_version_bump/src/core/yaml_transformers/formatter/formatter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/tracker.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:test/test.dart';

/// Mainly tracks paths from a node to be printed to screen.
///
/// This generalization helps test [DualTrackerKey] as it is a subtype of said
/// class.
typedef _MockFormatterTracker = FormatterTracker<TrackerKey<String>>;

void main() {
  late _MockFormatterTracker tracker;

  const key = TrackerKey<String>.fromValue('key', Origin.custom);
  const otherKey = TrackerKey<String>.fromValue('otherKey', Origin.custom);

  const path = TrackerKey<String>.fromValue('this/path', Origin.custom);

  void resetTracker(
    _MockFormatterTracker tracker, {
    int? cursor,
    int? currentTolerance,
  }) {
    tracker.history.clear();
    tracker.trackerState.clear();
    tracker
      ..currentCursor = cursor ?? 0
      ..currentTolerance = currentTolerance ?? 0;
  }

  group('tracker with default max tolerance', () {
    setUpAll(() => tracker = _MockFormatterTracker());

    test('adds single path being tracked', () {
      final expectedState = {
        key: [path],
        otherKey: [path],
      };

      // Tracks by file index
      tracker.add(fileIndex: 0, keys: [key, otherKey], value: path);

      expect(tracker.trackerState, equals(expectedState));

      addTearDown(() => resetTracker(tracker));
    });

    test('adds old path & updated paths being tracked', () {
      final dualPath = DualTrackerKey<String, String>.fromValue(
        key: path.key,
        otherKey: 'updated/path',
        origin: Origin.custom,
      );

      final expectedState = {
        key: [dualPath],
        otherKey: [dualPath],
      };

      tracker.add(fileIndex: 0, keys: [key, otherKey], value: dualPath);

      expect(tracker.trackerState, equals(expectedState));

      addTearDown(() => resetTracker(tracker));
    });

    test('swaps current cursor when new file index is added', () {
      tracker
        ..add(fileIndex: 0, keys: [key], value: path) // initial index
        ..add(fileIndex: 1, keys: [otherKey], value: path); // new index

      expect(tracker.currentCursor, equals(1));
      expect(tracker.currentTolerance, equals(0));
      expect(tracker.maxTolerance, equals(0));

      /// Current state is last index with respect to max tolerance allowable.
      ///
      /// Max tolerance is 0, thus immediately swaps tracker state to last
      /// index. And old state moved to history linked to file index
      expect(
        tracker.trackerState,
        equals({
          otherKey: [path],
        }),
      );

      expect(
        tracker.getFromHistory(0), // old state is in history
        equals({
          key: [path],
        }),
      );

      addTearDown(() => resetTracker(tracker));
    });
  });

  group('tracker with custom max tolerance', () {
    setUpAll(() => tracker = _MockFormatterTracker(maxTolerance: 1));

    test('does not swap until max tolerance is exceeded', () {
      tracker
        ..add(fileIndex: 0, keys: [key], value: path) // initial index
        ..add(fileIndex: 1, keys: [otherKey], value: path); // new index

      expect(tracker.currentCursor, equals(0));
      expect(tracker.currentTolerance, equals(1));
      expect(tracker.maxTolerance, equals(1));

      /// Current state remains until [currentTolerance > maxTolerance]
      expect(
        tracker.trackerState,
        equals({
          key: [path],
        }),
      );

      expect(
        tracker.getFromHistory(1), // updated state is in history
        equals({
          otherKey: [path],
        }),
      );
    });

    test('swaps once max tolerance is exceeded', () {
      // Exceed max tolerance
      tracker.add(fileIndex: 1, keys: [key], value: path);
      
      expect(tracker.currentCursor, equals(1));
      expect(tracker.currentTolerance, equals(0)); // Resets tolerance
      expect(
        tracker.trackerState,
        equals({
          otherKey: [path],
          key: [path],
        }),
      );

      expect(
        tracker.getFromHistory(0), // old state is in history
        equals({
          key: [path],
        }),
      );
    });
  });
}
