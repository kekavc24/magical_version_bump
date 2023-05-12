import 'package:magical_version_bump/src/utils/command_handler/mixins/command_mixins.dart';
import 'package:magical_version_bump/src/utils/models/magical_data_model.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _MockFileHandler with HandleFile {}

void main() {
  group('handle file mixin test', () {
    late Logger logger;
    late _MockFileHandler fileHandler;

    setUp(() {
      logger = _MockLogger();
      fileHandler = _MockFileHandler();

      when(() => logger.progress(any())).thenReturn(_MockProgress());
    });

    test('read file from current directory', () async {
      const path = 'pubspec.yaml';

      final data = await fileHandler.readFile(
        requestPath: false,
        logger: logger,
      );

      verify(() => logger.progress('Reading file')).called(1);

      expect(data, isA<YamlFileData>());
      expect(data.path, path);
    });

    test('read file from custom directory', () async {
      const path = 'test/files/fake.yaml';

      when(
        () => logger.prompt(
          'Please enter the path to file:',
          defaultValue: any(
            named: 'defaultValue',
          ),
        ),
      ).thenReturn(path);

      final data = await fileHandler.readFile(
        requestPath: true,
        logger: logger,
      );

      verify(() => logger.progress('Reading file')).called(1);

      expect(data, isA<YamlFileData>());
      expect(data.path, path);
    });

    test('wrong path provided', () async {
      const path = 'fake';

      when(
        () => logger.prompt(
          'Please enter the path to file:',
          defaultValue: any(
            named: 'defaultValue',
          ),
        ),
      ).thenReturn(path);

      final data = fileHandler.readFile(
        requestPath: true,
        logger: logger,
      );

      verify(() => logger.progress('Reading file')).called(1);

      expect(() async => data, throwsA(isException));
    });
  });
}
