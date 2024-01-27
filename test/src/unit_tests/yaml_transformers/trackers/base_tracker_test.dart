import 'package:magical_version_bump/src/core/yaml_transformers/trackers/tracker.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:test/test.dart';

import '../../../../helpers/helpers.dart';

final class _MockTracker extends DualTracker<String, String, dynamic>
    with MapHistory<String, String, String, dynamic> {
  @override
  TrackerKey<String> createKey(dynamic value, {required Origin origin}) {
    return super.createKey(value, origin: origin);
  }
}

void main() {
  final tracker = _MockTracker();

  group('tracker adds key', () {
    test('of type TrackerKey for non-"MapEntry" type', () {
      final trackerKey = tracker.createKey('key', origin: Origin.custom);

      expect(
        trackerKey,
        isA<TrackerKey<dynamic>>()
            .having((tracker) => tracker.key, 'key', 'key'),
      );
    });

    test('of type DualTrackerKey for "MapEntry" type', () {
      final trackerKey = tracker.createKey(
        const MapEntry('key', 'value'),
        origin: Origin.custom,
      );

      expect(
        trackerKey,
        isA<DualTrackerKey<dynamic, dynamic>>()
            .having((tracker) => tracker.key, 'key', 'key')
            .having((tracker) => tracker.otherKey, 'otherKey', 'value'),
      );
    });
  });

  group('tracks data', () {
    test('and allows for keys with same value but different origin', () {
      final key = tracker.createKey('key', origin: Origin.key);
      final customKey = tracker.createKey('key', origin: Origin.custom);
      final valueKey = tracker.createKey('key', origin: Origin.value);
      final pairKey = tracker.createKey('key', origin: Origin.pair);

      final keys = {key, customKey, valueKey, pairKey};

      tracker.trackerState.addEntries(
        keys.map((e) => MapEntry(e, 'value')),
      );

      expect(tracker.trackerState.keys, equals(keys));
      addTearDown(tracker.trackerState.clear);
    });
  });

  group('manages history', () {
    test('and returns null when empty', () {
      final data = tracker.getFromHistory('someMissingKey');

      expect(data, isNull);
    });

    test('stores current data in tracker to history with cursor', () {
      final key = tracker.createKey('myKey', origin: Origin.custom);
      const value = 'myValue';

      tracker.trackerState.putIfAbsent(key, () => value);
      expect(tracker.reset(cursor: 'myCursor'), equals({key: value}));
    });

    test('throws an exception when trying to store a duplicate cursor', () {
      expect(
        () => tracker.reset(cursor: 'myCursor'),
        throwsCustomException('This cursor is already tracked!'),
      );
    });
  });
}
