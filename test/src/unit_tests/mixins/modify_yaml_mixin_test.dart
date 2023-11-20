import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../../helpers/helpers.dart';

class _FakeYamlModifier with ModifyYaml {}

void main() {
  late _FakeYamlModifier modifier;
  late FileOutput yamlOutput;

  const version = '11.11.11';

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

  setUp(() {
    modifier = _FakeYamlModifier();
    yamlOutput = (file: fakeYaml, fileAsMap: loadYaml(fakeYaml));
  });

  group('updates', () {
    test('key at root', () async {
      final dictionary = (
        updateMode: UpdateMode.overwrite,
        rootKeys: ['version'],
        data: '10.10.10+10',
      );

      final updatedFile = await modifier.updateYamlFile(
        yamlOutput,
        dictionary: dictionary,
      );

      final updateValue = await readNestedNodes<String>(
        updatedFile,
        ['version'],
      );

      expect(updateValue, '10.10.10+10');
    });

    test('creates missing root key', () async {
      final dictionary = (
        updateMode: UpdateMode.overwrite,
        rootKeys: ['name', 'test name'],
        data: 'Test One, Two, Three',
      );

      final updatedFile = await modifier.updateYamlFile(
        yamlOutput,
        dictionary: dictionary,
      );

      final updateValue = await readNestedNodes<String>(
        updatedFile,
        ['name', 'test name'],
      );

      expect(updateValue, 'Test One, Two, Three');
    });

    test('overwrites existing key with new values', () async {
      final dictionary = (
        updateMode: UpdateMode.overwrite,
        rootKeys: ['test', 'nested-test'],
        data: 'Test One, Two, Three',
      );

      final updatedFile = await modifier.updateYamlFile(
        yamlOutput,
        dictionary: dictionary,
      );

      final updateValue = await readNestedNodes<String>(
        updatedFile,
        ['test', 'nested-test'],
      );

      expect(updateValue, 'Test One, Two, Three');
    });

    test('appends value to existing key with one value', () async {
      final dictionary = (
        updateMode: UpdateMode.append,
        rootKeys: ['test', 'nested-test', 'nested-value'],
        data: 'Test One, Two, Three',
      );

      final updatedFile = await modifier.updateYamlFile(
        yamlOutput,
        dictionary: dictionary,
      );

      final updateValue = await readNestedNodes<YamlList>(
        updatedFile,
        ['test', 'nested-test', 'nested-value'],
      );

      expect(updateValue, equals(['value', 'Test One, Two, Three']));
    });

    test('appends value to existing key with list of values', () async {
      final dictionary = (
        updateMode: UpdateMode.append,
        rootKeys: ['test', 'nested-test', 'nested-list'],
        data: 'Test One, Two, Three',
      );

      final updatedFile = await modifier.updateYamlFile(
        yamlOutput,
        dictionary: dictionary,
      );

      final updateValue = await readNestedNodes<YamlList>(
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
        updateMode: UpdateMode.append,
        rootKeys: ['test', 'nested-test', 'nested-map'],
        data: {
          'value': 'another value',
          'test map': 'Test One, Two, Three',
        },
      );

      final updatedFile = await modifier.updateYamlFile(
        yamlOutput,
        dictionary: dictionary,
      );

      final updateValue = await readNestedNodes<YamlMap>(
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
