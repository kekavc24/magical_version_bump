import 'package:magical_version_bump/src/core/mixins/command_mixins.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _FakeFileHandler with HandleFile {}

void main() {
  late Logger logger;
  late _FakeFileHandler handler;

  final testpath = getTestFile();
  const defaultPath = 'pubspec.yaml';
  const wrongPath = 'pubspec';

  setUp(() {
    logger = _MockLogger();
    handler = _FakeFileHandler();

    when(() => logger.progress(any())).thenReturn(_MockProgress());
  });

  group('handle file mixin test', () {
    test('reads pubspec.yaml file from path', () async {
      final data = await handler.readFile(logger: logger);

      verify(() => logger.progress('Reading file')).called(1);

      expect(data.path, defaultPath);
    });

    test('reads pubspec.yaml file from path set by user', () async {
      final data = await handler.readFile(
        logger: logger,
        setPath: testpath,
      );

      verify(() => logger.progress('Reading file')).called(1);

      expect(data.path, testpath);
    });

    test(
      'reads pubspec.yaml file from path provided by user in prompt',
      () async {
        when(
          () => logger.prompt(
            'Please enter the path to file:',
            defaultValue: any(
              named: 'defaultValue',
            ),
          ),
        ).thenReturn(testpath);

        final data = await handler.readFile(requestPath: true, logger: logger);

        verify(() => logger.progress('Reading file')).called(1);

        expect(data.path, testpath);
      },
    );

    test('throws error if path provided is not absolute', () async {
      when(
        () => logger.prompt(
          'Please enter the path to file:',
          defaultValue: any(
            named: 'defaultValue',
          ),
        ),
      ).thenReturn(wrongPath);

      final data = handler.readFile(
        requestPath: true,
        logger: logger,
      );

      verify(() => logger.progress('Reading file')).called(1);

      expect(() async => data, throwsA(isException));
    });
  });
}
