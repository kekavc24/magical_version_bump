import 'dart:io';

import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:yaml_edit/yaml_edit.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  late _MockLogger logger;
  late MagicalVersionBumpCommandRunner commandRunner;

  const defaultVersion = '10.10.10';
  const defaultAlternate = '$defaultVersion-test+10';
  const path = 'fake.yaml';

  /// Will always have file input. Indirectly tests cmd inputs too. Both will
  /// always call the same function to bump versions.
  final defaultArgs = [
    'bump',
    'semver',
    '-i',
    'file',
    path,
    '--no-check-for-update',
  ];

  setUp(() {
    logger = _MockLogger();
    commandRunner = MagicalVersionBumpCommandRunner(logger: logger);
  });

  tearDown(() async {
    final editor = YamlEditor(await File(path).readAsString())
      ..update(['version'], defaultVersion)
      ..update(['version-alternate'], defaultAlternate);

    await File(path).writeAsString(editor.toString());
  });

  group('command utils', () {
    test('reads version from cmd', () async {
      final argsToIgnore = {'-i', 'file', path};

      final args = [
        ...defaultArgs.whereNot(argsToIgnore.contains),
        defaultVersion,
      ];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info(defaultVersion)).called(1);
    });

    test('reads version from file', () async {
      check(await commandRunner.run(defaultArgs)).equals(ExitCode.success.code);
      verify(() => logger.info(defaultVersion)).called(1);
    });

    test('reads version from file with custom version param', () async {
      final args = [...defaultArgs, '--version-param', 'version-alternate'];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info(defaultAlternate)).called(1);
    });
  });

  group('bump core version', () {
    test('bumps major version', () async {
      final args = [...defaultArgs, '-t', 'major'];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info('11.0.0')).called(1);
    });

    test('bumps minor version', () async {
      final args = [...defaultArgs, '-t', 'minor'];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info('10.11.0')).called(1);
    });

    test('bumps patch version', () async {
      final args = [...defaultArgs, '-t', 'patch'];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info('10.10.11')).called(1);
    });
  });

  group('appends missing metadata', () {
    test('using leading period modifier', () async {
      final args = [
        ...defaultArgs,
        '--prerelease-target',
        '{}{.test}',
        '--build-target',
        '{}{.10}',
      ];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info(defaultAlternate)).called(1);
    });

    test('using leading non-period modifier', () async {
      final args = [
        ...defaultArgs,
        '--prerelease-target',
        '{}{test}',
        '--build-target',
        '{}{10}',
      ];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info(defaultAlternate)).called(1);
    });

    test('using accessor with no trailing modifier', () async {
      final args = [...defaultArgs, '--prerelease-target', '{test}{}'];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info('$defaultVersion-test')).called(1);
    });
  });

  group('bumps metadata', () {
    test('based on first numerical part', () async {
      final args = [...defaultArgs, '-b', '', '--vp', 'version-alternate'];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info('$defaultVersion-test+11')).called(1);
    });

    test('clears metadata', () async {
      final args = [
        ...defaultArgs,
        '-r',
        '{}{}',
        '--kb',
        '-k',
        'version-alternate',
      ];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info('$defaultVersion+10')).called(1);
    });

    test('updates metadata in place, no trailing modifier', () async {
      final args = [
        ...defaultArgs,
        '-r',
        '{test}{}',
        '--kb',
        '-k',
        'version-alternate',
      ];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info('$defaultVersion-test-1+10')).called(1);
    });

    test('updates metadata in place, period trailing modifier', () async {
      final args = [
        ...defaultArgs,
        '-r',
        '{test}{.}',
        '--kb',
        '-k',
        'version-alternate',
      ];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info('$defaultVersion-test-1+10')).called(1);
    });

    test('appends 1, if index out of range', () async {
      final args = [
        ...defaultArgs,
        '-r',
        '{1}{.}',
        '--kb',
        '-k',
        'version-alternate',
      ];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info('$defaultVersion-test.1+10')).called(1);
    });

    test('appends after accessor, when present', () async {
      final args = [
        ...defaultArgs,
        '-r',
        '{test}{.extra}',
        '--kb',
        '-k',
        'version-alternate',
      ];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info('$defaultVersion-test.extra+10')).called(1);
    });

    test('updates metadata in place, non-period trailing modifier', () async {
      final args = [
        ...defaultArgs,
        '-r',
        '{test}{test.extra}',
        '--kb',
        '-k',
        'version-alternate',
      ];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info('$defaultVersion-test-1.extra+10')).called(1);
    });

    test('replaces existing metadata', () async {
      final args = [
        ...defaultArgs,
        '-r',
        '{test}{release-candidate}',
        '--kb',
        '-k',
        'version-alternate',
      ];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(
        () => logger.info('$defaultVersion-release-candidate+10'),
      ).called(1);
    });

    test('appends trailing "1", trailing modifier ends with "."', () async {
      final args = [
        ...defaultArgs,
        '-r',
        '{test}{beta.}',
        '--kb',
        '-k',
        'version-alternate',
      ];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info('$defaultVersion-beta.1+10')).called(1);
    });
  });

  group('sets', () {
    test('updates version via setters', () async {
      final args = [...defaultArgs, '--set', 'M=0,m=0,p=0,pre=0,b=0'];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info('0.0.0-0+0')).called(1);
    });
  });

  group('preset', () {
    test('presets all info, bumps major', () async {
      final args = [
        ...defaultArgs,
        '--preset',
        'all',
        '--set',
        'M=0,m=0,p=0,pre=0,b=0',
        '-t',
        'major',
      ];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info('0.0.0')).called(1);
    });

    test('presets only core version, bumps major', () async {
      final args = [
        ...defaultArgs,
        '--preset',
        'version',
        '--set',
        'M=0,m=0,p=0,pre=0,b=0',
        '-t',
        'major',
      ];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info('1.0.0-0+0')).called(1);
    });

    test('presets only metadata, bumps major', () async {
      final args = [
        ...defaultArgs,
        '--preset',
        'metadata',
        '--set',
        'M=0,m=0,p=0,pre=0,b=0',
        '-t',
        'major',
      ];

      check(await commandRunner.run(args)).equals(ExitCode.success.code);
      verify(() => logger.info('0.0.0')).called(1);
    });
  });
}
