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

  const modifyFlags = [
    '--major',
    '--minor',
    '--patch',
    '--build-number',
    '--with-path'
  ];

  const bumpArgs = ['modify', '-b', ...modifyFlags];
  const dumpArgs = ['modify', '-d', ...modifyFlags];

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
  });

  group('throws error', () {
    test('command must have arguments error', () async {
      final args = ['modify'];
      final result = await commandRunner.run(args);

      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err('No arguments found')).called(1);
    });

    test('invalid arguments passed to command', () async {
      final args = ['modify', 'undefined-arg'];
      final result = await commandRunner.run(args);

      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err('undefined-arg is not a defined flag')).called(1);
    });
  });

  group('independent versioning (absolute)', () {
    test('bumps up all versions', () async {
      const version = '11.11.11+11';
      final result = await commandRunner.run([...bumpArgs, 'absolute']);

      final bumpedVersion = await readFileNode('version');

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, version);
    });

    test('bumps down all versions', () async {
      const version = '9.9.9+9';
      final result = await commandRunner.run([...dumpArgs, 'absolute']);

      final bumpedVersion = await readFileNode('version');

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, version);
    });
  });

  group('collective versioning (relative)', () {
    test('bumps up major version and build-number', () async {
      const version = '11.0.0+11';
      final result = await commandRunner.run(bumpArgs);

      final bumpedVersion = await readFileNode('version');

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, version);
    });

    test('bumps up minor version and build-number', () async {
      const version = '10.11.0+11';
      final result = await commandRunner.run(
        [...bumpArgs.where((element) => element != '--major')],
      );

      final bumpedVersion = await readFileNode('version');

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, version);
    });

    test('bumps up patch version and build-number', () async {
      const version = '10.10.11+11';
      final result = await commandRunner.run(
        [
          ...bumpArgs.where(
            (element) => element != '--major' && element != '--minor',
          )
        ],
      );

      final bumpedVersion = await readFileNode('version');

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, version);
    });

    test('throws error when dumping down version', () async {
      final result = await commandRunner.run(dumpArgs);

      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err(
          'This versioning strategy does not allow bumping down versions',
        ),
      ).called(1);
    });

    test('gets highest weighted target and bumps it (major)', () async {
      const version = '11.0.0+11';
      final result = await commandRunner.run(bumpArgs);

      final bumpedVersion = await readFileNode('version');

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, version);
    });
  });

  group('modify with custom path', () {
    test(
      'sets path and bumps all versions even with duplicated set-path flags',
      () async {
        const version = '11.11.11+11';
        final result = await commandRunner.run(
          [...bumpArgs, 'absolute', 'set-path=$path', 'set-path=$path'],
        );

        final bumpedVersion = await readFileNode('version');

        verify(
          () => logger.warn('Duplicate flags were found when path was set'),
        ).called(1);

        expect(result, equals(ExitCode.success.code));
        expect(bumpedVersion, version);
      },
    );
  });

  tearDown(() async => resetFile());
}
