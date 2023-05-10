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
  const version = '8.8.8+8';
  const argsWithVersion = ['change', version, '--with-path'];
  const noVersionInArgs = ['change', '--with-path'];

  setUp(() {
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
  });

  group('change command test', () {
    test('changes version in yaml', () async {
      final result = await commandRunner.run(argsWithVersion);

      final changedVersion = await readFileVersion();

      expect(result, equals(ExitCode.success.code));
      expect(changedVersion, version);
    });

    test('prompts for version if not provided', () async {
      // Rejects base version
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

      final result = await commandRunner.run(noVersionInArgs);

      final changedVersion = await readFileVersion();

      expect(result, equals(ExitCode.success.code));
      expect(changedVersion, version);
    });
  });

  tearDown(() async => resetFile());
}
