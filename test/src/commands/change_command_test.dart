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

  const nameArg = '--name=Test File';
  const descArg = '--description=This is a test';
  const versionArg = '--yaml-version=8.8.8+8';
  const homepageArg = '--homepage=https://url.to.homepage';
  const repoArg = '--repository=https://url.to.repository-on-github';
  const issueArg = '--issue_tracker=https://url.to.issue-tracker';
  const docArg = '--documentation=https://url.to.documentation';
  const preleaseArg = '--set-prerelease=test';
  const buildArg = '--set-build=100';
  const setVersionArg = '--set-version=8.8.8+8';

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

  group('throws error', () {
    // test('command must have arguments error', () async {
    //   final args = ['change'];
    //   final result = await commandRunner.run(args);

    //   expect(result, equals(ExitCode.usage.code));
    //   verify(() => logger.err('No arguments found')).called(1);
    // });

    test('invalid arguments passed to command', () async {
      final args = ['change', 'undefined-arg'];
      final result = await commandRunner.run(args);

      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err('undefined-arg is not a defined flag')).called(1);
    });

    test('changes the version and keeps build info', () async {
      const error =
          '''You cannot change to new version and keep old prelease and build info''';

      final result = await commandRunner.run(
        ['change', '--set-version=8.8.8', '--keep-build', '--set-path=$path'],
      );

      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(error)).called(1);
    });
  });

  group('change command test', () {
    test('changes name in yaml', () async {
      final result = await commandRunner.run(
        ['change', nameArg, '--with-path'],
      );

      final expectedChange = nameArg.split('=').last;

      final current = await readFileNode('name');
      await resetFile(node: 'name', nodeValue: 'magical_version_bump');

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });

    test('changes description in yaml', () async {
      final result = await commandRunner.run(
        ['change', descArg, '--with-path'],
      );

      final expectedChange = descArg.split('=').last;

      final current = await readFileNode('description');
      await resetFile(
        node: 'description',
        nodeValue: 'A Very Good description',
      );

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });

    test('changes version in yaml', () async {
      final result = await commandRunner.run(
        ['change', versionArg, '--with-path'],
      );

      final expectedChange = versionArg.split('=').last;

      final current = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });

    test('changes homepage url in yaml', () async {
      final result = await commandRunner.run(
        ['change', homepageArg, '--with-path'],
      );

      final expectedChange = homepageArg.split('=').last;

      final current = await readFileNode('homepage');
      await resetFile(node: 'homepage', remove: true);

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });

    test('changes repository url in yaml', () async {
      final result = await commandRunner.run(
        ['change', repoArg, '--with-path'],
      );

      final expectedChange = repoArg.split('=').last;

      final current = await readFileNode('repository');
      await resetFile(node: 'repository', remove: true);

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });

    test('changes issue-tracker url in yaml', () async {
      final result = await commandRunner.run(
        ['change', issueArg, '--with-path'],
      );

      final expectedChange = issueArg.split('=').last;

      final current = await readFileNode('issue_tracker');
      await resetFile(node: 'issue_tracker', remove: true);

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });

    test('changes documentation url in yaml', () async {
      final result = await commandRunner.run(
        ['change', docArg, '--with-path'],
      );

      final expectedChange = docArg.split('=').last;

      final current = await readFileNode('documentation');
      await resetFile(node: 'documentation', remove: true);

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });

    test('changes the version using set-version', () async {
      final result = await commandRunner.run(
        ['change', setVersionArg, '--keep-build', '--set-path=$path'],
      );

      const expectedChange = '8.8.8+8';

      final current = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });

    test('changes the version and removes build & prelease info', () async {
      final result = await commandRunner.run(
        ['change', '--set-version=8.8.8', '--set-path=$path'],
      );

      const expectedChange = '8.8.8';

      final current = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });

    test('changes the prerelease in version and removes build info', () async {
      final result = await commandRunner.run(
        ['change', preleaseArg, '--set-path=$path'],
      );

      const expectedChange = '10.10.10-test';

      final current = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });

    test('changes the prerelease in version and keeps build info', () async {
      final result = await commandRunner.run(
        ['change', preleaseArg, '--set-path=$path', '--keep-build'],
      );

      const expectedChange = '10.10.10-test+10';

      final current = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });

    test('changes the build and removes prerelease info', () async {
      final result = await commandRunner.run(
        ['change', buildArg, '--set-path=$path'],
      );

      const expectedChange = '10.10.10+100';

      final current = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });

    test('changes the build and sets prerelease info', () async {
      final result = await commandRunner.run(
        ['change', preleaseArg, buildArg, '--set-path=$path'],
      );

      const expectedChange = '10.10.10-test+100';

      final current = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });
  });
}
