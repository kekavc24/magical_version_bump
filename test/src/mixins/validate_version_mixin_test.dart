import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../helpers/helpers.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _FakeVersionValidator with ValidateVersion {}

void main() {
  late Logger logger;
  late _FakeVersionValidator validator;
  late YamlMap yamlMap;
  late YamlMap nullYamlMap;
  late YamlMap invalidYamlMap;

  const version = '1.1.1';

  setUp(() {
    logger = _MockLogger();
    validator = _FakeVersionValidator();
    yamlMap = loadYaml('version: $version') as YamlMap;
    invalidYamlMap = loadYaml('version: 1.') as YamlMap;
    nullYamlMap = loadYaml('version: ') as YamlMap;

    when(() => logger.progress(any())).thenReturn(_MockProgress());

    // Reject base version
    when(
      () => logger.confirm(
        any(),
        defaultValue: any(
          named: 'defaultValue',
        ),
      ),
    ).thenReturn(false);

    // Add default version used for testing as version desired
    when(
      () => logger.prompt(
        'Enter version number : ',
        defaultValue: any(
          named: 'defaultValue',
        ),
      ),
    ).thenReturn(version);
  });

  group('validate versions', () {
    test('validates version from yaml map as valid', () async {
      final validatedVersion = await validator.validateVersion(
        logger: logger,
        isModify: true,
        yamlMap: yamlMap,
      );

      verify(() => logger.progress('Checking version number')).called(1);

      expect(validatedVersion, version);
    });

    test('validates version passed as valid', () async {
      final validatedVersion = await validator.validateVersion(
        logger: logger,
        version: version,
      );

      verify(() => logger.progress('Checking version number')).called(1);

      expect(validatedVersion, version);
    });

    test('throws error when yaml map is null', () async {
      const violation = 'YAML Map cannot be null';

      final validatedVersion = validator.validateVersion(
        logger: logger,
        isModify: true,
      );

      expect(() async => validatedVersion, throwsViolation(violation));
    });
  });

  group('prompts for version', () {
    test('prompts when yaml map version is null', () async {
      final validatedVersion = await validator.validateVersion(
        logger: logger,
        isModify: true,
        yamlMap: nullYamlMap,
      );

      verify(() => logger.progress('Checking version number')).called(1);

      expect(validatedVersion, version);
    });

    test('prompts when version passed is null', () async {
      final validatedVersion = await validator.validateVersion(
        logger: logger,
      );

      verify(() => logger.progress('Checking version number')).called(1);

      expect(validatedVersion, version);
    });

    test('prompts when yaml map version is invalid', () async {
      final validatedVersion = await validator.validateVersion(
        logger: logger,
        isModify: true,
        yamlMap: invalidYamlMap,
      );

      verify(() => logger.progress('Checking version number')).called(1);

      expect(validatedVersion, version);
    });

    test('prompts when version passed is invalid', () async {
      final validatedVersion = await validator.validateVersion(
        logger: logger,
        version: '1.',
      );

      verify(() => logger.progress('Checking version number')).called(1);

      expect(validatedVersion, version);
    });
  });
}
