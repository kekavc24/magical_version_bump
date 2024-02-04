import 'package:magical_version_bump/src/core/yaml_transformers/formatter/formatter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/tracker.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:test/test.dart';

/// Mainly tracks paths from a node to be printed to screen.
typedef _MockFormatterTracker = FormatterTracker;

void main() {
  late _MockFormatterTracker tracker;

  const key = TrackerKey<String>.fromValue('key', Origin.custom);
  const otherKey = TrackerKey<String>.fromValue('otherKey', Origin.custom);

  const FormattedPathInfo pathInfo = (path: 'this/path', updatedPath: null);

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
        key: [pathInfo],
        otherKey: [pathInfo],
      };

      // Tracks by file index
      tracker.add(fileIndex: 0, keys: [key, otherKey], pathInfo: pathInfo);

      expect(tracker.trackerState, equals(expectedState));

      addTearDown(() => resetTracker(tracker));
    });

    test('swaps current cursor when new file index is added', () {
      tracker
        ..add(fileIndex: 0, keys: [key], pathInfo: pathInfo) // initial index
        ..add(fileIndex: 1, keys: [otherKey], pathInfo: pathInfo); // new index

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
          otherKey: [pathInfo],
        }),
      );

      expect(
        tracker.getFromHistory(0), // old state is in history
        equals({
          key: [pathInfo],
        }),
      );

      addTearDown(() => resetTracker(tracker));
    });
  });

  group('tracker with custom max tolerance', () {
    setUpAll(() => tracker = _MockFormatterTracker(maxTolerance: 1));

    test('does not swap until max tolerance is exceeded', () {
      tracker
        ..add(fileIndex: 0, keys: [key], pathInfo: pathInfo) // initial index
        ..add(fileIndex: 1, keys: [otherKey], pathInfo: pathInfo); // new index

      expect(tracker.currentCursor, equals(0));
      expect(tracker.currentTolerance, equals(1));
      expect(tracker.maxTolerance, equals(1));

      /// Current state remains until [currentTolerance > maxTolerance]
      expect(
        tracker.trackerState,
        equals({
          key: [pathInfo],
        }),
      );

      expect(
        tracker.getFromHistory(1), // updated state is in history
        equals({
          otherKey: [pathInfo],
        }),
      );
    });

    test('swaps once max tolerance is exceeded', () {
      // Exceed max tolerance
      tracker.add(fileIndex: 1, keys: [key], pathInfo: pathInfo);

      expect(tracker.currentCursor, equals(1));
      expect(tracker.currentTolerance, equals(0)); // Resets tolerance
      expect(
        tracker.trackerState,
        equals({
          otherKey: [pathInfo],
          key: [pathInfo],
        }),
      );

      expect(
        tracker.getFromHistory(0), // old state is in history
        equals({
          key: [pathInfo],
        }),
      );
    });
  });
}
