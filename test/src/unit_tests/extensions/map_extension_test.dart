import 'package:magical_version_bump/src/core/yaml_transformers/data/pair_definition/custom_pair_type.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/map_extensions.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

void main() {
  // Map with test values
  final mappy = <String, dynamic>{
    'key': 'value',
    'deep key': {
      'deeper key': {
        'deepest key': {
          'absolute deep key': 'value',
          'another key': ['value'],
        },
      },
    },
    'key-with-list': [
      'one value',
      {'nested key': 'value'},
      ['value-in-list'],
    ],
  };

  group('recursively reads value', () {
    test('when key is at root', () {
      const targetKey = 'key';

      final valueAtKey = mappy.recursiveRead<String>(
        path: [],
        target: targetKey,
      );

      expect(valueAtKey, equals('value'));
    });

    test('when key is deeply nested', () {
      final keys = ['deep key', 'deeper key', 'deepest key'];
      const targetKey = 'absolute deep key';

      final valueAtKey = mappy.recursiveRead<String>(
        path: keys,
        target: targetKey,
      );

      expect(valueAtKey, equals('value'));
    });

    test('when key is in map nested in a list', () {
      final keys = ['key-with-list'];
      const targetKey = 'nested key';

      final valueAtKey = mappy.recursiveRead<String>(
        path: keys,
        target: targetKey,
      );

      expect(valueAtKey, equals('value'));
    });
  });

  group('nested update appends', () {
    test(
      'string to deepest key/value pair and converts value to list',
      () {
        final localMap = {...mappy};

        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'absolute deep key';
        const update = 'another value';

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: keys,
          updateMode: UpdateMode.append,
        );

        final valueAtKey = updatedMap.recursiveRead<List<dynamic>>(
          path: keys,
          target: targetKey,
        );

        expect(valueAtKey, equals(['value', update]));
      },
    );

    test(
      'list of values to deepest key/value pair and converts value to list',
      () {
        final localMap = {...mappy};

        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'another key';
        const update = ['another value', 'double other value'];

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: keys,
          updateMode: UpdateMode.append,
        );

        final valueAtKey = updatedMap.recursiveRead<List<dynamic>>(
          path: keys,
          target: targetKey,
        );

        expect(valueAtKey, equals(['value', ...update]));
      },
    );

    test(
      'adds string to deepest key whose value is a list',
      () {
        final localMap = {...mappy};

        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'another key';
        const update = 'another value';

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: keys,
          updateMode: UpdateMode.append,
        );

        final valueAtKey = updatedMap.recursiveRead<List<dynamic>>(
          path: keys,
          target: targetKey,
        );

        expect(valueAtKey, equals(['value', update]));
      },
    );

    test(
      'adds list of values to deepest key whose value is a list',
      () {
        final localMap = {...mappy};

        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'another key';
        const update = ['another value', 'double other value'];

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: keys,
          updateMode: UpdateMode.append,
        );

        final valueAtKey = updatedMap.recursiveRead<List<dynamic>>(
          path: keys,
          target: targetKey,
        );

        expect(valueAtKey, equals(['value', ...update]));
      },
    );

    test(
      'adds map of values to deepest key whose value is a map',
      () {
        final localMap = {...mappy};

        final keys = ['deep key', 'deeper key'];
        const targetKey = 'deepest key';
        const update = {'another value': 'double other value'};

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: keys,
          updateMode: UpdateMode.append,
        );

        final valueAtKey = updatedMap.recursiveRead<Map<dynamic, dynamic>>(
          path: keys,
          target: targetKey,
        );

        expect(
          valueAtKey,
          equals({
            'absolute deep key': 'value',
            'another key': ['value'],
            ...update,
          }),
        );
      },
    );

    test('a value when key is in a map nested in a list', () {
      final localMap = {...mappy};

      final keys = ['key-with-list'];
      const targetKey = 'nested key';
      const update = 'another value';

      final updatedMap = localMap.recursivelyUpdate(
        update,
        target: targetKey,
        path: keys,
        updateMode: UpdateMode.append,
      );

      final valueAtKey = updatedMap.recursiveRead<List<dynamic>>(
        path: keys,
        target: targetKey,
      );

      expect(valueAtKey, equals(['value', update]));
    });

    test(
      'a map to a key with only a string, converts it to list',
      () {
        final localMap = {...mappy};

        const targetKey = 'key';
        const update = {'test': 'works'};

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: [],
          updateMode: UpdateMode.append,
        );

        final valueAtKey = updatedMap.recursiveRead<List<dynamic>>(
          path: [],
          target: targetKey,
        );

        expect(valueAtKey, equals(['value', update]));
      },
    );

    test(
      'when appending a string or list of values to a map of values',
      () {
        final localMap = {...mappy};

        const targetKey = 'deep key';
        const update = 'test';

        final valueBefore = localMap[targetKey];

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: [],
          updateMode: UpdateMode.append,
        );

        final valueAtKey = updatedMap.recursiveRead<List<dynamic>>(
          path: [],
          target: targetKey,
        );

        expect(valueAtKey, equals([valueBefore, update]));
      },
    );
  });

  group('nested update overwrites', () {
    test(
      'deepest key/value pair and converts value to another string',
      () {
        final localMap = {...mappy};

        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'absolute deep key';
        const update = 'another value';

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: keys,
          updateMode: UpdateMode.overwrite,
        );

        final valueAtKey = updatedMap.recursiveRead<String>(
          path: keys,
          target: targetKey,
        );

        expect(valueAtKey, equals(update));
      },
    );

    test(
      'deepest key/value pair and converts value to a list of values',
      () {
        final localMap = {...mappy};

        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'absolute deep key';
        const update = ['another value', 'double other value'];

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: keys,
          updateMode: UpdateMode.overwrite,
        );

        final valueAtKey = updatedMap.recursiveRead<List<dynamic>>(
          path: keys,
          target: targetKey,
        );

        expect(valueAtKey, equals(update));
      },
    );

    test(
      'deepest key/value pair and converts value to a key/value pair',
      () {
        final localMap = {...mappy};

        final keys = ['deep key', 'deeper key'];
        const targetKey = 'deepest key';
        const update = {'another value': 'double other value'};

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: keys,
          updateMode: UpdateMode.overwrite,
        );

        final valueAtKey = updatedMap.recursiveRead<Map<dynamic, dynamic>>(
          path: keys,
          target: targetKey,
        );

        expect(valueAtKey, equals(update));
      },
    );

    test('when key is in a map nested in a list', () {
      final localMap = {...mappy};

      final keys = ['key-with-list'];
      const targetKey = 'nested key';
      const update = 'another value';

      final updatedMap = localMap.recursivelyUpdate(
        update,
        target: targetKey,
        path: keys,
        updateMode: UpdateMode.overwrite,
      );

      final valueAtKey = updatedMap.recursiveRead<String>(
        path: keys,
        target: targetKey,
      );

      expect(valueAtKey, equals(update));
    });
  });

  group('nested update adds missing key', () {
    test('when at root', () {
      final localMap = {...mappy};

      final missingRootKeys = ['missing root'];
      const missingTargetkey = 'missing target';
      const update = 'update';

      final updatedMap = localMap.recursivelyUpdate(
        update,
        target: missingTargetkey,
        path: missingRootKeys,
        updateMode: UpdateMode.append,
      );

      final valueAtKey = updatedMap.recursiveRead<List<dynamic>>(
        path: missingRootKeys,
        target: missingTargetkey,
      );

      expect(valueAtKey, equals([update]));
    });

    test('when nested', () {
      final localMap = {...mappy};

      final rootKeys = ['deep key'];
      const missingTargetkey = 'missing target';
      const update = 'update';

      final updatedMap = localMap.recursivelyUpdate(
        update,
        target: missingTargetkey,
        path: rootKeys,
        updateMode: UpdateMode.append,
      );

      final valueAtKey = updatedMap.recursiveRead<List<dynamic>>(
        path: rootKeys,
        target: missingTargetkey,
      );

      expect(valueAtKey, equals([update]));
    });
  });

  group('nested update replace', () {
    test('renames list of keys in path', () {
      final localMap = {
        'deeper key': {
          'deepest key': {
            'absolute deep key': 'value',
            'another key': ['value'],
          },
        },
      };

      final replacements = <String, String>{
        'deeper key': 'updated key',
        'another key': 'final update',
      };

      // We don't care about the value
      final nodeData = NodeData.stringSkeleton(
        path: const ['deeper key', 'deepest key'],
        key: 'another key',
        value: '',
      );

      final expectedMap = {
        'updated key': {
          'deepest key': {
            'absolute deep key': 'value',
            'final update': ['value'],
          },
        },
      };

      final updatedMap = localMap.updateIndexedMap(
        null,
        target: nodeData.key,
        path: nodeData.precedingKeys,
        keyAndReplacement: replacements,
        value: null,
      );

      expect(updatedMap, equals(expectedMap));
    });

    test('renames key when nested in a list', () {
      final localMap = <dynamic, dynamic>{
        'key-with-list': [
          'one value',
          {'nested key': 'value'},
          ['value-in-list'],
        ],
      };

      final replacements = <String, String>{
        'nested key': 'updated key',
      };

      final target = createPair<Key>(value: 'nested key', indices: [1]);
      final path = ['key-with-list']
          .map(
            (e) => createPair<Key>(value: e),
          )
          .toList();

      final expectedMap = {
        'key-with-list': [
          'one value',
          {'updated key': 'value'},
          ['value-in-list'],
        ],
      };

      final updatedMap = localMap.updateIndexedMap(
        null,
        target: target,
        path: path,
        keyAndReplacement: replacements,
        value: null,
      );

      expect(collectionsMatch(expectedMap, updatedMap), true);
    });

    test('replaces value', () {
      final localMap = <dynamic, dynamic>{
        'deep key': {
          'deeper key': 'value',
        },
      };

      final target = createPair<Key>(value: 'deeper key');
      final path = createListOfPair<Key>(values: ['deep key'], indices: {});
      final value = createPair<Value>(value: 'value', indices: [0]);

      final updatedMap = localMap.updateIndexedMap(
        'update',
        target: target,
        path: path,
        keyAndReplacement: {},
        value: value,
      );

      final expectedMap = {
        'deep key': {
          'deeper key': 'update',
        },
      };

      expect(collectionsMatch(expectedMap, updatedMap), true);
    });

    test('replaces value nested in list', () {
      final localMap = <dynamic, dynamic>{
        'deep key': {
          'deeper key': [
            'one value',
            {'nested key': 'value'},
            ['value-in-list'],
          ],
        },
      };

      final target = createPair<Key>(value: 'deeper key');
      final path = createListOfPair<Key>(values: ['deep key'], indices: {});
      final value = createPair<Value>(value: 'one value', indices: [0]);

      final updatedMap = localMap.updateIndexedMap(
        'update',
        target: target,
        path: path,
        keyAndReplacement: {},
        value: value,
      );

      final expectedMap = {
        'deep key': {
          'deeper key': [
            'update',
            {'nested key': 'value'},
            ['value-in-list'],
          ],
        },
      };

      expect(collectionsMatch(expectedMap, updatedMap), true);
    });

    test('replaces value in list nested in another list', () {
      final localMap = <dynamic, dynamic>{
        'deep key': {
          'deeper key': [
            'one value',
            {'nested key': 'value'},
            ['value-in-list'],
          ],
        },
      };

      final target = createPair<Key>(value: 'deeper key');
      final path = createListOfPair<Key>(values: ['deep key'], indices: {});
      final value = createPair<Value>(value: 'value-in-list', indices: [2, 0]);

      final updatedMap = localMap.updateIndexedMap(
        'update',
        target: target,
        path: path,
        keyAndReplacement: {},
        value: value,
      );

      final expectedMap = {
        'deep key': {
          'deeper key': [
            'one value',
            {'nested key': 'value'},
            ['update'],
          ],
        },
      };

      expect(collectionsMatch(expectedMap, updatedMap), true);
    });
  });

  group('nested update throws exception', () {
    test(
      '''when path is not exhausted and value encountered at path key is not a map''',
      () {
        final localMap = {...mappy};

        const targetKey = 'missing key';
        const update = {'test': 'error'};

        expect(
          () => localMap.recursivelyUpdate(
            update,
            target: targetKey,
            path: ['key'],
            updateMode: UpdateMode.append,
          ),
          throwsCustomException(
            '''Cannot append new values due to an existing value at "key". You need to overwrite this path key.''',
          ),
        );
      },
    );
  });
}
