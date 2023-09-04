import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../../helpers/helpers.dart';

class _FakeYamlModifier with ModifyYaml {}

void main() {
  late _FakeYamlModifier modifier;
  late YamlMap testYamlMap;

  const version = '11.11.11';
  const versionWithBuild = '$version+11';

  final majorTarget = <String>['major'];
  final minorTarget = <String>['minor'];
  final patchTarget = <String>['patch'];
  final buildTarget = <String>['build-number'];

  const fakeYaml = '''
  version: $version
  test:
    nested-test:
      nested-value: value
      nested-list:
        - value
        - another value

      nested-map:
        value: another value
''';

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

  setUp(() {
    modifier = _FakeYamlModifier();
    testYamlMap = YamlMap.wrap(mappy);
  });

  group('independent versioning (absolute)', () {
    test('bumps up only major version', () async {
      const bumpedVersion = '12.11.11';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        version,
        versionTargets: majorTarget,
        strategy: ModifyStrategy.absolute,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('bumps up only minor version', () async {
      const bumpedVersion = '11.12.11';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        version,
        versionTargets: minorTarget,
        strategy: ModifyStrategy.absolute,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('bumps up only patch version', () async {
      const bumpedVersion = '11.11.12';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        version,
        versionTargets: patchTarget,
        strategy: ModifyStrategy.absolute,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('bumps up only build number', () async {
      const bumpedVersion = '11.11.11+12';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        versionWithBuild,
        versionTargets: buildTarget,
        strategy: ModifyStrategy.absolute,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('appends and bumps up only build number', () async {
      const bumpedVersion = '11.11.11+1';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        version,
        versionTargets: buildTarget,
        strategy: ModifyStrategy.absolute,
      );

      expect(dynamicBump.version, bumpedVersion);
    });
  });

  group('collective versioning (relative)', () {
    test('collectively bumps up major version', () async {
      const bumpedVersion = '12.0.0';

      final dynamicBump = await modifier.dynamicBump(
        version,
        versionTargets: majorTarget,
        strategy: ModifyStrategy.relative,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('collectively bumps up/down minor version', () async {
      const bumpedVersion = '11.12.0';

      final dynamicBump = await modifier.dynamicBump(
        version,
        versionTargets: minorTarget,
        strategy: ModifyStrategy.relative,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('collectively bumps up/down patch version', () async {
      const bumpedVersion = '11.11.12';

      final dynamicBump = await modifier.dynamicBump(
        version,
        versionTargets: patchTarget,
        strategy: ModifyStrategy.relative,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('throws error when more than one targets are added', () async {
      final future = modifier.dynamicBump(
        version,
        versionTargets: [...majorTarget, ...patchTarget, ...buildTarget],
        strategy: ModifyStrategy.relative,
      );

      expect(
        () async => future,
        throwsViolation(
          'Expected only one target for this versioning strategy',
        ),
      );
    });
  });

  group('nested update appends', () {
    test(
      'string to deepest key/value pair and converts value to list',
      () {
        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'deeper deepest key';
        const update = 'another value';

        final updatedValue = modifier.updateNestedTarget(
          keys: keys,
          yamlMap: testYamlMap,
          targetKey: targetKey,
          update: update,
          append: true,
        );

        final expectedValue = {
          targetKey: ['value', update],
        };

        expect(updatedValue.failed, false);
        expect(updatedValue.failedReason, isNull);
        expect(updatedValue.finalDepth, 0);
        expect(updatedValue.updatedValue, equals(expectedValue));
      },
    );

    test(
      'list of values to deepest key/value pair and converts value to list',
      () {
        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'deeper deepest key';
        const update = ['another value', 'double other value'];

        final updatedValue = modifier.updateNestedTarget(
          keys: keys,
          yamlMap: testYamlMap,
          targetKey: targetKey,
          update: update,
          append: true,
        );

        final expectedValue = {
          targetKey: ['value', ...update],
        };

        expect(updatedValue.failed, false);
        expect(updatedValue.failedReason, isNull);
        expect(updatedValue.finalDepth, 0);
        expect(updatedValue.updatedValue, equals(expectedValue));
      },
    );

    test(
      'adds string to deepest key whose value is a list',
      () {
        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'another deepest key';
        const update = 'another value';

        final updatedValue = modifier.updateNestedTarget(
          keys: keys,
          yamlMap: testYamlMap,
          targetKey: targetKey,
          update: update,
          append: true,
        );

        final expectedValue = {
          targetKey: ['value', update],
        };

        expect(updatedValue.failed, false);
        expect(updatedValue.failedReason, isNull);
        expect(updatedValue.finalDepth, 0);
        expect(updatedValue.updatedValue, equals(expectedValue));
      },
    );

    test(
      'adds list of values to deepest key whose value is a list',
      () {
        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'another deepest key';
        const update = ['another value', 'double other value'];

        final updatedValue = modifier.updateNestedTarget(
          keys: keys,
          yamlMap: testYamlMap,
          targetKey: targetKey,
          update: update,
          append: true,
        );

        final expectedValue = {
          targetKey: ['value', ...update],
        };

        expect(updatedValue.failed, false);
        expect(updatedValue.failedReason, isNull);
        expect(updatedValue.finalDepth, 0);
        expect(updatedValue.updatedValue, equals(expectedValue));
      },
    );

    test(
      'adds map of values to deepest key whose value is a map',
      () {
        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'other depeest key';
        const update = {'another value': 'double other value'};

        final updatedValue = modifier.updateNestedTarget(
          keys: keys,
          yamlMap: testYamlMap,
          targetKey: targetKey,
          update: update,
          append: true,
        );

        final expectedValue = {
          targetKey: {
            'absolute deep key': 'value',
            ...update,
          },
        };

        expect(updatedValue.failed, false);
        expect(updatedValue.failedReason, isNull);
        expect(updatedValue.finalDepth, 0);
        expect(updatedValue.updatedValue, equals(expectedValue));
      },
    );
  });

  group('nested update overwrites', () {
    test(
      'deepest key/value pair and converts value to string',
      () {
        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'deeper deepest key';
        const update = 'another value';

        final updatedValue = modifier.updateNestedTarget(
          keys: keys,
          yamlMap: testYamlMap,
          targetKey: targetKey,
          update: update,
          append: false,
        );

        final expectedValue = {
          targetKey: 'another value',
        };

        expect(updatedValue.failed, false);
        expect(updatedValue.failedReason, isNull);
        expect(updatedValue.finalDepth, 0);
        expect(updatedValue.updatedValue, equals(expectedValue));
      },
    );

    test(
      'deepest key/value pair and converts value to list of values',
      () {
        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'deeper deepest key';
        const update = ['another value', 'double other value'];

        final updatedValue = modifier.updateNestedTarget(
          keys: keys,
          yamlMap: testYamlMap,
          targetKey: targetKey,
          update: update,
          append: false,
        );

        final expectedValue = {
          targetKey: update,
        };

        expect(updatedValue.failed, false);
        expect(updatedValue.failedReason, isNull);
        expect(updatedValue.finalDepth, 0);
        expect(updatedValue.updatedValue, equals(expectedValue));
      },
    );

    test(
      'deepest key/value pair and converts value to map of values',
      () {
        final keys = ['deep key', 'deeper key', 'deepest key'];
        const targetKey = 'deeper deepest key';
        const update = {'another value': 'double other value'};

        final updatedValue = modifier.updateNestedTarget(
          keys: keys,
          yamlMap: testYamlMap,
          targetKey: targetKey,
          update: update,
          append: false,
        );

        final expectedValue = {
          targetKey: update,
        };

        expect(updatedValue.failed, false);
        expect(updatedValue.failedReason, isNull);
        expect(updatedValue.finalDepth, 0);
        expect(updatedValue.updatedValue, equals(expectedValue));
      },
    );
  });

  group('nested update terminates', () {
    test('when key is missing at root', () {
      final keys = ['missing root key', 'deeper key'];
      const targetKey = 'deeper deepest key';
      const update = 'another value';

      final updatedValue = modifier.updateNestedTarget(
        keys: keys,
        yamlMap: testYamlMap,
        targetKey: targetKey,
        update: update,
        append: true,
      );

      expect(updatedValue.failed, false);
      expect(updatedValue.failedReason, null);
      expect(updatedValue.finalDepth, 2);
      expect(updatedValue.updatedValue, null);
    });

    test('when nested key is missing', () {
      final keys = ['deep key', 'missing root key'];
      const targetKey = 'deeper deepest key';
      const update = 'another value';

      final updatedValue = modifier.updateNestedTarget(
        keys: keys,
        yamlMap: testYamlMap,
        targetKey: targetKey,
        update: update,
        append: true,
      );

      expect(updatedValue.failed, false);
      expect(updatedValue.failedReason, null);
      expect(updatedValue.finalDepth, 2);
      expect(updatedValue.updatedValue, null);
    });

    test('when target key is missing', () {
      final keys = ['deep key', 'deeper key'];
      const targetKey = 'missing key';
      const update = 'another value';

      final updatedValue = modifier.updateNestedTarget(
        keys: keys,
        yamlMap: testYamlMap,
        targetKey: targetKey,
        update: update,
        append: true,
      );

      expect(updatedValue.failed, false);
      expect(updatedValue.failedReason, null);
      expect(updatedValue.finalDepth, 0);
      expect(updatedValue.updatedValue, null);
    });

    test(
      'when target key is missing but current root key will be overwritten',
      () {
        final keys = ['key'];
        const targetKey = 'missing key';
        const update = 'another value';

        final updatedValue = modifier.updateNestedTarget(
          keys: keys,
          yamlMap: testYamlMap,
          targetKey: targetKey,
          update: update,
          append: false,
        );

        expect(updatedValue.failed, false);
        expect(updatedValue.failedReason, isNull);
        expect(updatedValue.finalDepth, 0);
        expect(updatedValue.updatedValue, null);
      },
    );

    test(
      'and fails to append to a nested target key if root key is not a map',
      () {
        final keys = ['key'];
        const targetKey = 'missing key';
        const update = 'another value';

        final updatedValue = modifier.updateNestedTarget(
          keys: keys,
          yamlMap: testYamlMap,
          targetKey: targetKey,
          update: update,
          append: true,
        );

        expect(updatedValue.failed, true);
        expect(updatedValue.failedReason, 'Cannot append at ${keys.first}');
        expect(updatedValue.finalDepth, 1);
        expect(updatedValue.updatedValue, null);
      },
    );

    test('and fails to append map to string/list of values', () {
      final keys = ['deep key', 'deeper key', 'deepest key'];
      const targetKey = 'deeper deepest key';
      const update = {'another value': 'double other value'};

      final updatedValue = modifier.updateNestedTarget(
        keys: keys,
        yamlMap: testYamlMap,
        targetKey: targetKey,
        update: update,
        append: true,
      );

      expect(updatedValue.failed, true);
      expect(
        updatedValue.failedReason,
        'Cannot append new values at $targetKey',
      );
      expect(updatedValue.finalDepth, 0);
      expect(updatedValue.updatedValue, isNull);
    });

    test('and fails to append string to map', () {
      final keys = ['deep key', 'deeper key', 'deepest key'];
      const targetKey = 'other depeest key';
      const update = 'append value';

      final updatedValue = modifier.updateNestedTarget(
        keys: keys,
        yamlMap: testYamlMap,
        targetKey: targetKey,
        update: update,
        append: true,
      );

      expect(updatedValue.failed, true);
      expect(
        updatedValue.failedReason,
        'Cannot append new mapped values at $targetKey',
      );
      expect(updatedValue.finalDepth, 0);
      expect(updatedValue.updatedValue, isNull);
    });

    test('and fails to append list of values to map', () {
      final keys = ['deep key', 'deeper key', 'deepest key'];
      const targetKey = 'other depeest key';
      const update = ['append value'];

      final updatedValue = modifier.updateNestedTarget(
        keys: keys,
        yamlMap: testYamlMap,
        targetKey: targetKey,
        update: update,
        append: true,
      );

      expect(updatedValue.failed, true);
      expect(
        updatedValue.failedReason,
        'Cannot append new mapped values at $targetKey',
      );
      expect(updatedValue.finalDepth, 0);
      expect(updatedValue.updatedValue, isNull);
    });
  });

  group('converts unused keys to dart map', () {
    test('for one key', () {
      final map = modifier.convertToDartMap(
        YamlMap.wrap({}),
        append: false,
        pathKeys: [],
        missingKeys: ['one key'],
        targetKey: 'targetKey',
        data: 'data',
      );

      final expectedMap = {
        'one key': {
          'targetKey': 'data',
        },
      };

      expect(map, equals(expectedMap));
    });

    test('for multiple keys', () {
      final map = modifier.convertToDartMap(
        YamlMap.wrap({}),
        append: false,
        pathKeys: [],
        missingKeys: ['one key', 'two key', 'three key'],
        targetKey: 'targetKey',
        data: 'data',
      );

      final expectedMap = {
        'one key': {
          'two key': {
            'three key': {
              'targetKey': 'data',
            },
          },
        },
      };

      expect(map, equals(expectedMap));
    });
  });

  group('formats output correctly', () {
    test('when recursive function reached 0 depth', () {
      final output = (
        failed: false,
        failedReason: null,
        finalDepth: 0,
        updatedValue: {
          'value': 'updated',
        },
      );

      final formattedOutput = modifier.formatOutput(
        YamlMap.wrap({}),
        append: false,
        rootKeys: ['test'],
        targetKey: 'target',
        data: 'data',
        output: output,
      );

      final expectedDataToSave = output.updatedValue;

      expect(formattedOutput.path, equals(['test']));
      expect(formattedOutput.dataToSave, expectedDataToSave);
    });

    test('when recursive function reached 0 depth but key was missing', () {
      const output = (
        failed: false,
        failedReason: null,
        finalDepth: 0,
        updatedValue: null,
      );

      final formattedOutput = modifier.formatOutput(
        YamlMap.wrap({}),
        append: false,
        rootKeys: ['test'],
        targetKey: 'target',
        data: 'data',
        output: output,
      );

      final expectedDataToSave = {'target': 'data'};

      expect(formattedOutput.path, equals(['test']));
      expect(formattedOutput.dataToSave, expectedDataToSave);
    });

    test('when the first and only root key was missing', () {
      const output = (
        failed: false,
        failedReason: null,
        finalDepth: 1,
        updatedValue: null,
      );

      final formattedOutput = modifier.formatOutput(
        YamlMap.wrap({}),
        append: false,
        rootKeys: ['test'],
        targetKey: 'target',
        data: 'data',
        output: output,
      );

      final expectedDataToSave = {'target': 'data'};

      expect(formattedOutput.path, equals(['test']));
      expect(formattedOutput.dataToSave, expectedDataToSave);
    });

    test('when the first root key was missing in a list of keys', () {
      const output = (
        failed: false,
        failedReason: null,
        finalDepth: 1,
        updatedValue: null,
      );

      final formattedOutput = modifier.formatOutput(
        YamlMap.wrap({}),
        append: false,
        rootKeys: ['test', 'other test key'],
        targetKey: 'target',
        data: 'data',
        output: output,
      );

      final expectedDataToSave = {
        'other test key': {'target': 'data'},
      };

      expect(formattedOutput.path, equals(['test']));
      expect(formattedOutput.dataToSave, expectedDataToSave);
    });

    test('when the missing root key is not at index 0', () {
      const output = (
        failed: false,
        failedReason: null,
        finalDepth: 3,
        updatedValue: null,
      );

      final formattedOutput = modifier.formatOutput(
        YamlMap.wrap({}),
        append: false,
        rootKeys: [
          'test',
          'other test key',
          'another key',
          'another test key',
        ],
        targetKey: 'target',
        data: 'data',
        output: output,
      );

      final expectedDataToSave = {
        'other test key': {
          'another key': {
            'another test key': {'target': 'data'},
          },
        },
      };

      expect(formattedOutput.path, equals(['test']));
      expect(formattedOutput.dataToSave, expectedDataToSave);
    });
  });

  group('updates yaml file', () {
    test('updates key at root', () async {
      final dictionary = (
        append: false,
        rootKeys: ['version'],
        data: '10.10.10+10',
      );

      final updatedFile = await modifier.updateYamlFile(fakeYaml, dictionary);

      final updateValue = readNestedNodes(updatedFile, ['version']);

      expect(updateValue, '10.10.10+10');
    });

    test('creates missing root key', () async {
      final dictionary = (
        append: false,
        rootKeys: ['name', 'test name'],
        data: 'Test One, Two, Three',
      );

      final updatedFile = await modifier.updateYamlFile(fakeYaml, dictionary);

      final updateValue = readNestedNodes(
        updatedFile,
        ['name', 'test name'],
      );

      expect(updateValue, 'Test One, Two, Three');
    });

    test('overwrites existing key with new values', () async {
      final dictionary = (
        append: false,
        rootKeys: ['test', 'nested-test'],
        data: 'Test One, Two, Three',
      );

      final updatedFile = await modifier.updateYamlFile(fakeYaml, dictionary);

      final updateValue = readNestedNodes(
        updatedFile,
        ['test', 'nested-test'],
      );

      expect(updateValue, 'Test One, Two, Three');
    });

    test('appends value to existing key with one value', () async {
      final dictionary = (
        append: true,
        rootKeys: ['test', 'nested-test', 'nested-value'],
        data: 'Test One, Two, Three',
      );

      final updatedFile = await modifier.updateYamlFile(fakeYaml, dictionary);

      final updateValue = readNestedNodes(
        updatedFile,
        ['test', 'nested-test', 'nested-value'],
      );

      expect(updateValue, equals(['value', 'Test One, Two, Three']));
    });

    test('appends value to existing key with list of values', () async {
      final dictionary = (
        append: true,
        rootKeys: ['test', 'nested-test', 'nested-list'],
        data: 'Test One, Two, Three',
      );

      final updatedFile = await modifier.updateYamlFile(fakeYaml, dictionary);

      final updateValue = readNestedNodes(
        updatedFile,
        ['test', 'nested-test', 'nested-list'],
      );

      expect(
        updateValue,
        equals(['value', 'another value', 'Test One, Two, Three']),
      );
    });

    test('appends map to existing key with map of values', () async {
      final dictionary = (
        append: true,
        rootKeys: ['test', 'nested-test', 'nested-map'],
        data: {
          'value': 'another value',
          'test map': 'Test One, Two, Three',
        },
      );

      final updatedFile = await modifier.updateYamlFile(fakeYaml, dictionary);

      final updateValue = readNestedNodes(
        updatedFile,
        ['test', 'nested-test', 'nested-map'],
      );

      expect(
        updateValue,
        equals(
          {
            'value': 'another value',
            'test map': 'Test One, Two, Three',
          },
        ),
      );
    });
  });
}
