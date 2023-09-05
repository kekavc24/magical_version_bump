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

    test(
      'when appending a new nested node to node with non-map nodes',
      () async {
        final args = [...defaultArgs, '--add', 'name|newNode=value'];

        final result = await commandRunner.run(args);

        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err('Cannot append at name')).called(1);
      },
    );
  });

  group('set command modifies nodes', () {
    test('changes name in yaml', () async {
      final args = [...defaultArgs, '--dictionary', 'name=$name'];

      final result = await commandRunner.run(args);

      final currentValue = await readFileNode('name');
      await resetFile(node: 'name', nodeValue: 'Fake');

      expect(result, equals(ExitCode.success.code));
      expect(currentValue, name);
    });

    test('changes description in yaml', () async {
      final args = [
        ...defaultArgs,
        '--dictionary',
        'description=$description',
      ];

      final result = await commandRunner.run(args);

      final currentValue = await readFileNode('description');
      await resetFile(
        node: 'description',
        nodeValue: 'A Very Good description',
      );

      expect(result, equals(ExitCode.success.code));
      expect(currentValue, description);
    });

    test('changes version in yaml', () async {
      final args = [...defaultArgs, '--set-version', version];

      final result = await commandRunner.run(args);

      verify(
        () => logger.warn(
          'Version flag detected. Must verify version is valid',
        ),
      ).called(1);

      final currentValue = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(currentValue, version);
    });

    test('changes homepage url in yaml', () async {
      final args = [...defaultArgs, '--dictionary', 'homepage=$homepage'];

      final result = await commandRunner.run(args);

      final currentValue = await readFileNode('homepage');
      await resetFile(node: 'homepage', remove: true);

      expect(result, equals(ExitCode.success.code));
      expect(currentValue, homepage);
    });

    test('creates new node with values and appends new ones', () async {
      final args = [
        ...defaultArgs,
        '--dictionary',
        'nested|value=string',
        '--add',
        'nested|list=string,list',
        '--add',
        'nested|map=string->list',
      ];

      final result = await commandRunner.run(args);

      const expectedValue = 'string';
      final expectedList = ['string', 'list'];
      final expectedMap = {'string': 'list'};

      final defaultStart = ['nested'];

      final createdValue = await readNestedNodes(
        null,
        [...defaultStart, 'value'],
      );
      final createdList = await readNestedNodes(
        null,
        [...defaultStart, 'list'],
      );
      final createdMap = await readNestedNodes(null, [...defaultStart, 'map']);

      await resetFile(node: 'nested', remove: true);

      expect(result, equals(ExitCode.success.code));
      expect(createdValue, expectedValue);
      expect(createdList, equals(expectedList));
      expect(createdMap, equals(expectedMap));
    });

    test('changes the prerelease in version and removes build info', () async {
      //
      final args = [...defaultArgs, preleaseArg];

      final result = await commandRunner.run(args);

      const expectedChange = '10.10.10-test';

      final currentValue = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(currentValue, expectedChange);
    });

    test('changes the prerelease in version and keeps build info', () async {
      final args = [...defaultArgs, preleaseArg, '--keep-build'];

      final result = await commandRunner.run(args);

      const expectedChange = '10.10.10-test+10';

      final currentValue = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(currentValue, expectedChange);
    });

    test('changes the build and removes prerelease info', () async {
      final args = [...defaultArgs, buildArg];

      final result = await commandRunner.run(args);

      const expectedChange = '10.10.10+100';

      final currentValue = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(currentValue, expectedChange);
    });

    test('changes the build and sets prerelease info', () async {
      final args = [...defaultArgs, preleaseArg, buildArg];

      final result = await commandRunner.run(args);

      const expectedChange = '10.10.10-test+100';

      final currentValue = await readFileNode('version');
      await resetFile();

      expect(result, equals(ExitCode.success.code));
      expect(currentValue, expectedChange);
    });
  });
}
