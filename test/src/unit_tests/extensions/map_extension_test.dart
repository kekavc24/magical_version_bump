import 'package:magical_version_bump/src/utils/extensions/map_extensions.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

void main() {
  // Map with test values
  final mappy = <String, dynamic>{
    'key': 'value',
    'deep key': {
      'deeper key': {
        'deepest key': {
          'deeper deepest key': 'value',
          'another deepest key': ['value'],
          'other depeest key': {
            'absolute deep key': 'value',
          },
        },
      },
    },
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
      const targetKey = 'deeper deepest key';

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
        const targetKey = 'deeper deepest key';
        const update = 'another value';

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: keys,
          append: true,
        );

        final valueAtKey = updatedMap.recursiveRead<List<String>>(
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
        const targetKey = 'deeper deepest key';
        const update = ['another value', 'double other value'];

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: keys,
          append: true,
        );

        final valueAtKey = updatedMap.recursiveRead<List<String>>(
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
        const targetKey = 'another deepest key';
        const update = 'another value';

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: keys,
          append: true,
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
        const targetKey = 'another deepest key';
        const update = ['another value', 'double other value'];

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: keys,
          append: true,
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

        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'other depeest key';
        const update = {'another value': 'double other value'};

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: keys,
          append: true,
        );

        final valueAtKey = updatedMap.recursiveRead<Map<dynamic, dynamic>>(
          path: keys,
          target: targetKey,
        );

        expect(
          valueAtKey,
          {
            'absolute deep key': 'value',
            ...update,
          },
        );
      },
    );
  });

  group('nested update overwrites', () {
    test(
      'deepest key/value pair and converts value to another string',
      () {
        final localMap = {...mappy};

        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'deeper deepest key';
        const update = 'another value';

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: keys,
          append: false,
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
        const targetKey = 'deeper deepest key';
        const update = ['another value', 'double other value'];

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: keys,
          append: false,
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

        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'deeper deepest key';
        const update = {'another value': 'double other value'};

        final updatedMap = localMap.recursivelyUpdate(
          update,
          target: targetKey,
          path: keys,
          append: false,
        );

        final valueAtKey = updatedMap.recursiveRead<Map<dynamic, dynamic>>(
          path: keys,
          target: targetKey,
        );

        expect(valueAtKey, equals(update));
      },
    );
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
        append: true,
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
        append: true,
      );

      final valueAtKey = updatedMap.recursiveRead<List<dynamic>>(
        path: rootKeys,
        target: missingTargetkey,
      );

      expect(valueAtKey, equals([update]));
    });
  });

  group('nested update throws exception', () {
    test(
      'when appending a map of values to string or list of values',
      () {
        final localMap = {...mappy};

        const targetKey = 'key';
        const update = {'test': 'error'};

        expect(
          () => localMap.recursivelyUpdate(
            update,
            target: targetKey,
            path: [],
            append: true,
          ),
          throwsViolation(
            '''Cannot append new values at "$targetKey". New value must be a String or List of Strings.''',
          ),
        );
      },
    );

    test(
      'when appending a string or list of values to a map of values',
      () {
        final localMap = {...mappy};

        const targetKey = 'deep key';
        const update = 'test';

        expect(
          () => localMap.recursivelyUpdate(
            update,
            target: targetKey,
            path: [],
            append: true,
          ),
          throwsViolation(
            '''Cannot append new mapped values at "$targetKey". New value must be a map too.''',
          ),
        );
      },
    );

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
            append: true,
          ),
          throwsViolation(
            '''Cannot append new values due to an existing value at "key". You need to overwrite this path key.''',
          ),
        );
      },
    );
  });
}
