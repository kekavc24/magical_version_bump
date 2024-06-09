import 'package:magical_version_bump/src/core/yaml_transformers/finders/finder.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:test/test.dart';

void main() {
  final defaultMap = {
    'key': 'value',
    'keyWithList': [
      'value',
      {'key': 'value'},
    ],
    'anotherKey': {
      'key': 'value',
    },
  };

  group('find all matches', () {
    group('in keys', () {
      test('when OrderType is loose. Any exist', () {
        final keysToFind = (
          keys: ['key', 'anotherKey'],
          orderType: OrderType.loose,
        );

        final finder = ValueFinder.findInDynamicValue(
          defaultMap,
          saveCounterToHistory: false,
          keysToFind: keysToFind,
          valuesToFind: null,
          pairsToFind: null,
        );

        final matches = finder.findAll().map((e) => e.toString());

        final expectedMatches = [
          'key/value',
          'keyWithList/key/value',
          'anotherKey/key/value',
        ];

        final counter = finder.counter!;

        expect(matches, equals(expectedMatches));
        expect(counter.getCount('key', origin: Origin.key), 3);
        expect(counter.getCount('anotherKey', origin: Origin.key), 1);
      });

      test('when OrderType is grouped. Both must exist', () {
        final keysToFind = (
          keys: ['key', 'anotherKey'],
          orderType: OrderType.grouped,
        );

        final finder = ValueFinder.findInDynamicValue(
          defaultMap,
          saveCounterToHistory: false,
          keysToFind: keysToFind,
          valuesToFind: null,
          pairsToFind: null,
        );

        final matches = finder.findAll().map((e) => e.toString());

        final expectedMatches = [
          'anotherKey/key/value',
        ];

        final counter = finder.counter!;

        expect(matches, equals(expectedMatches));
        expect(counter.getCount('key', origin: Origin.key), 1);
        expect(counter.getCount('anotherKey', origin: Origin.key), 1);
      });

      test('when OrderType is strict. Both must exist in specified order', () {
        final keysToFind = (
          keys: ['anotherKey', 'key'],
          orderType: OrderType.strict,
        );

        final finder = ValueFinder.findInDynamicValue(
          defaultMap,
          saveCounterToHistory: false,
          keysToFind: keysToFind,
          valuesToFind: null,
          pairsToFind: null,
        );

        final matches = finder.findAll().map((e) => e.toString());

        final expectedMatches = [
          'anotherKey/key/value',
        ];

        final counter = finder.counter!;

        expect(matches, equals(expectedMatches));
        expect(counter.getCount('key', origin: Origin.key), 1);
        expect(counter.getCount('anotherKey', origin: Origin.key), 1);
      });
    });

    group('in values', () {
      test(
        'when at root, nested in key with list or a value to a key in map',
        () {
          final finder = ValueFinder.findInDynamicValue(
            defaultMap,
            saveCounterToHistory: false,
            keysToFind: null,
            valuesToFind: ['value'],
            pairsToFind: null,
          );

          final matches = finder.findAll().map((e) => e.toString());

          final expectedMatches = [
            'key/value',
            'keyWithList/value',
            'keyWithList/key/value',
            'anotherKey/key/value',
          ];

          expect(matches, equals(expectedMatches));
          expect(finder.counter!.getCount('value', origin: Origin.value), 4);
        },
      );
    });

    group('in pairs', () {
      test('when only keys are pairs', () {
        final pairsToFind = {
          'keyWithList': 'key',
          'anotherKey': 'key',
        };

        final finder = ValueFinder.findInDynamicValue(
          defaultMap,
          saveCounterToHistory: false,
          keysToFind: null,
          valuesToFind: null,
          pairsToFind: pairsToFind,
        );

        final matches = finder.findAll().map((e) => e.toString());

        final expectedMatches = [
          'keyWithList/key/value',
          'anotherKey/key/value',
        ];

        final counter = finder.counter!;

        expect(matches, equals(expectedMatches));
        expect(
          counter.getCount(
            pairsToFind.entries.elementAt(0),
            origin: Origin.pair,
          ),
          1,
        );
        expect(
          counter.getCount(
            pairsToFind.entries.elementAt(1),
            origin: Origin.pair,
          ),
          1,
        );
      });

      test('when both keys & values are pairs', () {
        // TODO(kekavc24): Consider using list instead of map for pairs
        final pairsToFind = {
          'keyWithList': 'key',
          'anotherKey': 'key',
          'key': 'value',
        };

        final finder = ValueFinder.findInDynamicValue(
          defaultMap,
          saveCounterToHistory: false,
          keysToFind: null,
          valuesToFind: null,
          pairsToFind: pairsToFind,
        );

        final matches = finder.findAll().map((e) => e.toString());

        final expectedMatches = [
          'key/value',
          'keyWithList/key/value',
          'anotherKey/key/value',
        ];

        final counter = finder.counter!;

        expect(matches, equals(expectedMatches));
        expect(
          counter.getCount(
            const MapEntry('keyWithList', 'key'),
            origin: Origin.pair,
          ),
          1,
        );
        expect(
          counter.getCount(
            const MapEntry('anotherKey', 'key'),
            origin: Origin.pair,
          ),
          1,
        );
        expect(
          counter.getCount(
            const MapEntry('key', 'value'),
            origin: Origin.pair,
          ),
          3,
        );
      });
    });
  });

  group('find matches by count', () {
    test('without applying to each. Plain count', () {
      final keysToFind = (
        keys: ['key', 'anotherKey'],
        orderType: OrderType.loose,
      );

      final valuesToFind = ['value'];
      final pairsToFind = {
        'keyWithList': 'key',
      };

      final finder = ValueFinder.findInDynamicValue(
        defaultMap,
        saveCounterToHistory: false,
        keysToFind: keysToFind,
        valuesToFind: valuesToFind,
        pairsToFind: pairsToFind,
      );

      final matches = finder
          .findByCountSync(1, applyToEach: false)
          .map((output) => output.data.toString())
          .toList();

      // Just the first match
      final expectedMatches = ['key/value'];

      final counter = finder.counter!;

      expect(matches, expectedMatches);

      // Both 'key' & 'value' were found, even though we wanted just 1 match
      expect(counter.getCount('key', origin: Origin.key), 1);
      expect(counter.getCount('value', origin: Origin.value), 1);
      expect(counter.getCount('anotherKey', origin: Origin.key), 0);
      expect(
        counter.getCount(
          const MapEntry('keyWithList', 'key'),
          origin: Origin.pair,
        ),
        0,
      );
    });

    test(
      'applies to each. Count must be at least equal to or greater than limit',
      () {
        final keysToFind = (
          keys: ['key', 'anotherKey'],
          orderType: OrderType.loose,
        );

        final valuesToFind = ['value'];
        final pairsToFind = {
          'keyWithList': 'key',
        };

        final finder = ValueFinder.findInDynamicValue(
          defaultMap,
          saveCounterToHistory: false,
          keysToFind: keysToFind,
          valuesToFind: valuesToFind,
          pairsToFind: pairsToFind,
        );

        final matches = finder
            .findByCountSync(1, applyToEach: true)
            .map((output) => output.data.toString())
            .toList();

        // Just the first match
        final expectedMatches = [
          'key/value',
          'keyWithList/key/value',
          'anotherKey/key/value',
        ];

        final counter = finder.counter!;
        expect(matches, expectedMatches);

        /// * Each argument has equal chance to reach count of "1".
        /// * Some may be found more than once.
        expect(counter.getCount('key', origin: Origin.key), 1);
        expect(counter.getCount('value', origin: Origin.value), 1);
        expect(counter.getCount('anotherKey', origin: Origin.key), 1);
        expect(
          counter.getCount(
            const MapEntry('keyWithList', 'key'),
            origin: Origin.pair,
          ),
          1,
        );
      },
    );
  });
}
