import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:magical_version_bump/src/utils/models/magical_data_model.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../helpers/helpers.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _MockModifier with ModifyYamlFile {}

void main() {
  group('modify file mixin test', () {
    late Logger logger;
    late _MockModifier modifier;
    late YamlFileData yamlData;
    late YamlFileData invalidYamlData;

    const version = '7.7.7';
    const fakeFile = 'version: $version';

    setUp(() {
      logger = _MockLogger();
      modifier = _MockModifier();

      final yamlMap = loadYaml(fakeFile) as YamlMap;
      final invalidMap = loadYaml('version: ') as YamlMap;

      yamlData = YamlFileData(path: '', file: fakeFile, yamlMap: yamlMap);
      invalidYamlData = YamlFileData(
        path: '',
        file: 'version: ',
        yamlMap: invalidMap,
      );

      when(() => logger.progress(any())).thenReturn(_MockProgress());
    });

    test('major version number is bumped up', () async {
      const action = 'bump';

      final targets = ['major'];

      const expectedVersion = '8.7.7';

      final moddedData = await modifier.modifyFile(
        absoluteChange: false,
        yamlData: yamlData,
        logger: logger,
        action: action,
        targets: targets,
      );

      verify(() => logger.progress('Modifying version')).called(1);

      final bumpedVersion = getVersion(moddedData.modifiedFile);

      expect(moddedData.runtimeType, ModifiedFileData);
      expect(bumpedVersion, expectedVersion);
    });

    test('minor version number is bumped down', () async {
      const action = 'dump';

      final targets = ['minor'];

      const expectedVersion = '7.6.7';

      final moddedData = await modifier.modifyFile(
        absoluteChange: false,
        yamlData: yamlData,
        logger: logger,
        action: action,
        targets: targets,
      );

      verify(() => logger.progress('Modifying version')).called(1);

      final bumpedVersion = getVersion(moddedData.modifiedFile);

      expect(moddedData.runtimeType, ModifiedFileData);
      expect(bumpedVersion, expectedVersion);
    });

    test('patch version number is bumped up', () async {
      const action = 'bump';

      final targets = ['patch'];

      const expectedVersion = '7.7.8';

      final moddedData = await modifier.modifyFile(
        absoluteChange: false,
        yamlData: yamlData,
        logger: logger,
        action: action,
        targets: targets,
      );

      verify(() => logger.progress('Modifying version')).called(1);

      final bumpedVersion = getVersion(moddedData.modifiedFile);

      expect(moddedData.runtimeType, ModifiedFileData);
      expect(bumpedVersion, expectedVersion);
    });

    test('build number is appended and bumped up', () async {
      const action = 'bump';

      final targets = ['build-number'];

      // Appends +1 by default before bumping up if missing
      const expectedVersion = '7.7.7+2';

      final moddedData = await modifier.modifyFile(
        absoluteChange: false,
        yamlData: yamlData,
        logger: logger,
        action: action,
        targets: targets,
      );

      verify(() => logger.progress('Modifying version')).called(1);

      final bumpedVersion = getVersion(moddedData.modifiedFile);

      expect(moddedData.runtimeType, ModifiedFileData);
      expect(bumpedVersion, expectedVersion);
    });

    test('build number is appended and bumped down', () async {
      const action = 'dump';

      final targets = ['build-number'];

      // Appends +1 by default before bumping up if missing
      const expectedVersion = '7.7.7+0';

      final moddedData = await modifier.modifyFile(
        absoluteChange: false,
        yamlData: yamlData,
        logger: logger,
        action: action,
        targets: targets,
      );

      verify(() => logger.progress('Modifying version')).called(1);

      final bumpedVersion = getVersion(moddedData.modifiedFile);

      expect(moddedData.runtimeType, ModifiedFileData);
      expect(bumpedVersion, expectedVersion);
    });

    test('all version numbers are bumped up', () async {
      const action = 'bump';

      final targets = ['major', 'minor', 'patch', 'build-number'];

      const expectedVersion = '8.8.8+2';

      final moddedData = await modifier.modifyFile(
        absoluteChange: false,
        yamlData: yamlData,
        logger: logger,
        action: action,
        targets: targets,
      );

      verify(() => logger.progress('Modifying version')).called(1);

      final bumpedVersion = getVersion(moddedData.modifiedFile);

      expect(moddedData.runtimeType, ModifiedFileData);
      expect(bumpedVersion, expectedVersion);
    });

    test('prompts for version and adds default build-number', () async {
      const action = 'bump';

      final targets = ['major', 'minor', 'patch', 'build-number'];

      const expectedVersion = '8.8.8+2';

      // Rejects base version and adds default build number of 1
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

      final moddedData = await modifier.modifyFile(
        absoluteChange: false,
        yamlData: invalidYamlData,
        logger: logger,
        action: action,
        targets: targets,
      );

      verify(() => logger.progress('Modifying version')).called(1);

      verify(() => logger.progress('Checking version number')).called(1);

      final bumpedVersion = getVersion(moddedData.modifiedFile);

      expect(moddedData.runtimeType, ModifiedFileData);
      expect(bumpedVersion, expectedVersion);
    });

    test('prompts for build-number and adds default version', () async {
      const action = 'bump';

      final targets = ['major', 'minor', 'patch', 'build-number'];

      const expectedVersion = '1.1.1+8';

      // Rejects base build number and adds default version of 0.0.0
      when(
        () => logger.confirm(
          any(),
          defaultValue: any(
            named: 'defaultValue',
          ),
        ),
      ).thenReturn(true);

      // Tell it to add build number too
      when(
        () => logger.prompt(
          'Enter build number :',
          defaultValue: any(
            named: 'defaultValue',
          ),
        ),
      ).thenReturn('7');

      final moddedData = await modifier.modifyFile(
        absoluteChange: false,
        yamlData: invalidYamlData,
        logger: logger,
        action: action,
        targets: targets,
      );

      verify(() => logger.progress('Modifying version')).called(1);

      verify(() => logger.progress('Checking version number')).called(1);

      final bumpedVersion = getVersion(moddedData.modifiedFile);

      expect(moddedData.runtimeType, ModifiedFileData);
      expect(bumpedVersion, expectedVersion);
    });
  });
}
