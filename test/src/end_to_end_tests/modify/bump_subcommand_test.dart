import 'package:magical_version_bump/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

void main() {
  late Logger logger;
  late MagicalVersionBumpCommandRunner commandRunner;

  final path = getTestFile();
  final defaultArgs = ['modify', 'bump'];
  final defaultTargets = ['--targets', 'major,minor,patch,build-number'];

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
      final result = await commandRunner.run(defaultArgs);

      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err('Arguments cannot be empty or null')).called(1);
    });

    test('invalid arguments passed to command', () async {
      final args = [...defaultArgs, 'undefined-arg'];
      final result = await commandRunner.run(args);

      expect(result, equals(ExitCode.usage.code));
    });
  });

  group('independent versioning (absolute)', () {
    test('bumps up all versions', () async {
      const version = '11.11.11+11';
      final args = [
        ...defaultArgs,
        ...defaultTargets,
        '--strategy',
        'absolute',
        '--request-path',
      ];

      final result = await commandRunner.run(args);

      final bumpedVersion = await readFileNode('version');

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, version);
    });
  });

  group('collective versioning (relative)', () {
    test('bumps up major version and build-number', () async {
      const version = '11.0.0+11';
      final args = [
        ...defaultArgs,
        '--targets',
        'major,build-number',
        '--request-path',
      ];

      final result = await commandRunner.run(args);

      final bumpedVersion = await readFileNode('version');

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, version);
    });

    test('bumps up minor version and build-number', () async {
      const version = '10.11.0+11';
      final args = [
        ...defaultArgs,
        '--targets',
        'minor,build-number',
        '--request-path',
      ];

      final result = await commandRunner.run(args);

      final bumpedVersion = await readFileNode('version');

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, version);
    });

    test('bumps up patch version and build-number', () async {
      const version = '10.10.11+11';
      final args = [
        ...defaultArgs,
        '--targets',
        'patch,build-number',
        '--request-path',
      ];

      final result = await commandRunner.run(args);

      final bumpedVersion = await readFileNode('version');

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, version);
    });

    test('gets highest weighted target and bumps it (major)', () async {
      const version = '11.0.0+11';
      final args = [
        ...defaultArgs,
        ...defaultTargets,
        '--request-path',
      ];

      final result = await commandRunner.run(args);

      final bumpedVersion = await readFileNode('version');

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, version);
    });
  });

  group('modify with custom path', () {
    test(
      'sets path and bumps all versions even with duplicated directory option',
      () async {
        const version = '11.11.11+11';
        final args = [
          ...defaultArgs,
          ...defaultTargets,
          '--strategy',
          'absolute',
        ];

        final result = await commandRunner.run(
          [...args, '--directory=$path', '--directory=$path'],
        );

        final bumpedVersion = await readFileNode('version');

        expect(result, equals(ExitCode.success.code));
        expect(bumpedVersion, version);
      },
    );
  });

  group('modifies with setters', () {
    test('sets version before bumping major version', () async {
      const setVersion = '11.12.13';
      const updatedVersion = '12.0.0';

      final args = [
        ...defaultArgs,
        '--targets',
        'major',
        '--set-version=$setVersion',
        '--directory=$path',
      ];

      final result = await commandRunner.run(args);

      final bumpedVersion = await readFileNode('version');

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, updatedVersion);
    });

    test(
      'sets version and keeps build before bumping major version',
      () async {
        const setVersion = '11.12.13';

        // Version in fake.yaml is 10.10.10+10
        const updatedVersion = '12.0.0+10'; 

        final args = [
          ...defaultArgs,
          '--targets',
          'major',
          '--set-version=$setVersion',
          '--keep-build',
          '--directory=$path',
        ];

        final result = await commandRunner.run(args);

        final bumpedVersion = await readFileNode('version');

        expect(result, equals(ExitCode.success.code));
        expect(bumpedVersion, updatedVersion);
      },
    );

    test(
      'sets version only before bumping major version then sets build-number',
      () async {
        const setVersion = '11.12.13';
        const setBuild = '13';
        const updatedVersion = '12.0.0+$setBuild';

        final args = [
          ...defaultArgs,
        '--targets',
        'major',
          '--set-version=$setVersion',
          '--set-build=$setBuild',
          '--directory=$path',
        ];

        final result = await commandRunner.run(args);

        final bumpedVersion = await readFileNode('version');

        expect(result, equals(ExitCode.success.code));
        expect(bumpedVersion, updatedVersion);
      },
    );

    test('sets build after bumping old build-number', () async {
      const setBuild = '13';
      const updatedVersion = '10.10.10+13';

      final args = [
        ...defaultArgs,
        '--targets',
        'build-number',
        '--set-build=$setBuild',
        '--directory=$path',
      ];

      final result = await commandRunner.run(args);

      final bumpedVersion = await readFileNode('version');

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, updatedVersion);
    });

    test('sets prerelease and removes build after bumping it', () async {
      const setPre = 'alpha';
      const updatedVersion = '10.10.10-alpha';

      final args = [
        ...defaultArgs,
        '--targets',
        'build-number',
        '--set-prerelease=$setPre',
        '--directory=$path',
      ];

      final result = await commandRunner.run(args);

      final bumpedVersion = await readFileNode('version');

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, updatedVersion);
    });

    test('sets prerelease, bumps & keeps build', () async {
      const setPre = 'alpha';
      const updatedVersion = '10.10.10-alpha+11';

      final args = [
        ...defaultArgs,
        '--targets',
        'build-number',
        '--set-prerelease=$setPre',
        '--keep-build',
        '--directory=$path',
      ];

      final result = await commandRunner.run(args);

      final bumpedVersion = await readFileNode('version');

      expect(result, equals(ExitCode.success.code));
      expect(bumpedVersion, updatedVersion);
    });
  });

  tearDown(() async => resetFile());
}
