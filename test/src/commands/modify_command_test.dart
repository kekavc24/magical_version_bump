import 'package:magical_version_bump/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../helpers/helpers.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

void main() {
  late Logger logger;
  late MagicalVersionBumpCommandRunner commandRunner;

  const path = 'test/files/fake.yaml';
  const bumpArgs = [
    'modify',
    '-b',
    '--major',
    '--minor',
    '--patch',
    '--build-number',
    '--with-path'
  ];
  const dumpArgs = [
    'modify',
    '-d',
    '--major',
    '--minor',
    '--patch',
    '--build-number',
    '--with-path'
  ];

  setUp(() async {
    logger = _MockLogger();
    commandRunner = MagicalVersionBumpCommandRunner(
      logger: logger,
    );

    when(() => logger.progress(any())).thenReturn(_MockProgress());
    when(
      () => logger.prompt(
        'Please enter the path to file:',
        defaultValue: any(
          named: 'defaultValue',
        ),
      ),
    ).thenReturn(path);
    await resetFile();
  });

  tearDown(() async {
    await resetFile();
  });

  group('modify command test', () {
    test('bumps up all versions', () async {
      const version = '11.11.11+11';
      final result = await commandRunner.run(bumpArgs);

      final bumpedVersion = await readFileVersion();

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, version);
    });

    test('bumps down all versions', () async {
      const version = '9.9.9+9';
      final result = await commandRunner.run(dumpArgs);

      final bumpedVersion = await readFileVersion();

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, version);
    });

    test('command must have arguments error', () async {
      final args = ['modify'];
      final result = await commandRunner.run(args);

      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err('No arguments found')).called(1);
    });
  });
}
