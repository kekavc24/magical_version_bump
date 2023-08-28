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
  final argsWithNoPath = ['modify', 'set'];
  final defaultArgs = [...argsWithNoPath, '--directory=$path'];

  const name = 'Test File';
  const description = 'This is a test';
  const homepage = 'https://url.to.homepage';
  const repo = 'https://url.to.repository-on-github';
  const issue = 'https://url.to.issue-tracker';
  const docs = '=https://url.to.documentation';
  const preleaseArg = '--set-prerelease=test';
  const buildArg = '--set-build=100';
  const version = '8.8.8+8';

  setUp(() {
    logger = _MockLogger();
    commandRunner = MagicalVersionBumpCommandRunner(
      logger: logger,
    );

    when(() => logger.progress(any())).thenReturn(_MockProgress());
  });

  group('throws error', () {
    test('command must have arguments error', () async {
      final result = await commandRunner.run(argsWithNoPath);

      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err('Arguments cannot be empty or null')).called(1);
    });

    test('invalid arguments passed to command', () async {
      final args = [...defaultArgs, '--undefined-arg'];
      final result = await commandRunner.run(args);

      expect(result, equals(ExitCode.usage.code));
    });
  });

  group('change command test', () {
    test('changes name in yaml', () async {
      final args = [...defaultArgs, '--name', name];

      final result = await commandRunner.run(args);

      final current = await readFileNode('name');
      await resetFile(node: 'name', nodeValue: 'magical_version_bump');

      expect(result, equals(ExitCode.success.code));
      expect(current, name);
    });

    test('changes description in yaml', () async {
      final args = [...defaultArgs, '--description', description];

      final result = await commandRunner.run(args);

      final current = await readFileNode('description');
      await resetFile(
        node: 'description',
        nodeValue: 'A Very Good description',
      );

      expect(result, equals(ExitCode.success.code));
      expect(current, description);
    });

    test('changes version in yaml', () async {
      final args = [...defaultArgs, '--set-version', version];

      final result = await commandRunner.run(args);

      verify(
        () => logger.warn(
          'Version flag detected. Must verify version is valid',
        ),
      ).called(1);

      final current = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(current, version);
    });

    test('changes homepage url in yaml', () async {
      final args = [...defaultArgs, '--homepage', homepage];

      final result = await commandRunner.run(args);

      final current = await readFileNode('homepage');
      await resetFile(node: 'homepage', remove: true);

      expect(result, equals(ExitCode.success.code));
      expect(current, homepage);
    });

    test('changes repository url in yaml', () async {
      final args = [...defaultArgs, '--repository', repo];

      final result = await commandRunner.run(args);

      final current = await readFileNode('repository');
      await resetFile(node: 'repository', remove: true);

      expect(result, equals(ExitCode.success.code));
      expect(current, repo);
    });

    test('changes issue-tracker url in yaml', () async {
      final args = [...defaultArgs, '--issue_tracker', issue];

      final result = await commandRunner.run(args);

      final current = await readFileNode('issue_tracker');
      await resetFile(node: 'issue_tracker', remove: true);

      expect(result, equals(ExitCode.success.code));
      expect(current, issue);
    });

    test('changes documentation url in yaml', () async {
      final args = [...defaultArgs, '--documentation', docs];

      final result = await commandRunner.run(args);

      final current = await readFileNode('documentation');
      await resetFile(node: 'documentation', remove: true);

      expect(result, equals(ExitCode.success.code));
      expect(current, docs);
    });

    test('changes the prerelease in version and removes build info', () async {
      //
      final args = [...defaultArgs, preleaseArg];

      final result = await commandRunner.run(args);

      const expectedChange = '10.10.10-test';

      final current = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });

    test('changes the prerelease in version and keeps build info', () async {
      final args = [...defaultArgs, preleaseArg, '--keep-build'];

      final result = await commandRunner.run(args);

      const expectedChange = '10.10.10-test+10';

      final current = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });

    test('changes the build and removes prerelease info', () async {
      final args = [...defaultArgs, buildArg];

      final result = await commandRunner.run(args);

      const expectedChange = '10.10.10+100';

      final current = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });

    test('changes the build and sets prerelease info', () async {
      final args = [...defaultArgs, preleaseArg, buildArg];

      final result = await commandRunner.run(args);

      const expectedChange = '10.10.10-test+100';

      final current = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(current, expectedChange);
    });
  });
}
