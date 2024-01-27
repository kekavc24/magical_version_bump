import 'package:magical_version_bump/src/core/yaml_transformers/trackers/counter/generic_counter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/tracker.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:test/test.dart';

/// Use counter with history. Direct inherits from base [Counter]
typedef _MockCounter = CounterWithHistory<String, String, String>;

void main() {
  final counter = _MockCounter();

  group('basic counter with no history', () {
    test('returns 0 when entry is missing or not yet incremented', () {
      expect(counter.getCount('myValue', origin: Origin.custom), 0);
    });

    test('tracks count of a value', () {
      counter.increment(['myValue'], origin: Origin.custom);

      expect(counter.getCount('myValue', origin: Origin.custom), 1);
    });

    test('tracks count of value when from different origins', () {
      // same as previous, different origin
      counter.increment(['myValue'], origin: Origin.key);

      expect(counter.getCount('myValue', origin: Origin.key), 1);
      expect(counter.getCount('myValue', origin: Origin.custom), 1); // previous
    });

    test('obtains count when a TrackerKey wrapping value is used', () {
      const key = TrackerKey(key: 'myValue', origin: Origin.custom);

      expect(counter.getCountFromKey(key), 1);
    });

    test('obtains total count for all keys stored in it', () {
      // We added 2 keys once each
      expect(counter.getSumOfCount(), 2);

      addTearDown(counter.trackerState.clear); // Clear for next test
    });

    test('prefills keys into map whose count may be tracked in future', () {
      final keys = ['myValue', 'myOtherValue'];

      counter.prefill(keys, origin: Origin.custom);

      expect(counter.trackerState.keys.map((e) => e.key), equals(keys));
      expect(counter.getSumOfCount(), 0);
    });

    test('increments count of key if prefilled once more', () {
      final keys = ['myValue', 'myOtherValue', 'anotherValue'];

      counter.prefill(keys, origin: Origin.custom);

      expect(counter.trackerState.keys.map((e) => e.key), equals(keys));
      expect(counter.getSumOfCount(), 2); // Two keys added once more each.
    });
  });

  group('basic counter with history', () {
    test('returns null when no history is present', () {
      expect(
        counter.getCountFromHistory('test', 'myValue', Origin.custom),
        isNull,
      );
    });

    test('resets history and clears current state', () {
      final oldState = counter.reset(cursor: 'test');

      expect(counter.trackerState, equals({}));

      // We add various values in previous test
      expect(
        oldState,
        equals({
          const TrackerKey<String>.fromValue('myValue', Origin.custom): 1,
          const TrackerKey<String>.fromValue('myOtherValue', Origin.custom): 1,
          const TrackerKey<String>.fromValue('anotherValue', Origin.custom): 0,
        }),
      );
    });

    test('obtains valid count when stored in history', () {
      expect(
        counter.getCountFromHistory('test', 'myValue', Origin.custom),
        1,
      );
    });

    test('drops cursor from history', () {
      counter.dropCursor('test');

      expect(counter.getFromHistory('test'), isNull); // State linked to cursor
    });
  });
}
