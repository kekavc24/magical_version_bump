import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:magical_version_bump/src/utils/models/magical_data_model.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _FakeFileHandler with HandleFile {}

void main() {
  late Logger logger;
  late _FakeFileHandler handler;

  const testpath = 'test/files/fake.yaml';
  const defaultPath = 'pubspec.yaml';
  const wrongPath = 'pubspec';

  setUp(() {
    logger = _MockLogger();
    handler = _FakeFileHandler();

    when(() => logger.progress(any())).thenReturn(_MockProgress());
  });

  group('handle file mixin test', () {
    test('reads pubspec.yaml file from path', () async {
      final data = await handler.readFile(requestPath: false, logger: logger);

      verify(() => logger.progress('Reading file')).called(1);

      expect(data, isA<YamlFileData>());
      expect(data.path, defaultPath);
    });

    test('reads pubspec.yaml file from user provided path', () async {
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

      expect(data, isA<YamlFileData>());
      expect(data.path, testpath);
    });

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
