import 'package:magical_version_bump/src/core/handlers/file_handler/file_handler.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../../helpers/helpers.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _FakeFileHandler extends FileHandler {
  _FakeFileHandler();

  factory _FakeFileHandler.forTest({
    required bool requestPath,
    required String path,
    required Logger logger,
  }) {
    return _FakeFileHandler()
      ..requestPath = requestPath
      ..path = path
      ..fileLogger = logger;
  }

  _FakeFileHandler copyWith({bool? requestPath, String? path}) {
    return _FakeFileHandler.forTest(
      path: path ?? this.path,
      requestPath: requestPath ?? this.requestPath,
      logger: fileLogger,
    );
  }

  String getPath() => path;
}

void main() {
  late Logger logger;
  late _FakeFileHandler handler;

  final testpath = getTestFile();
  const defaultPath = 'pubspec.yaml';
  const wrongPath = 'pubspec';

  setUp(() {
    logger = _MockLogger();
    handler = _FakeFileHandler.forTest(
      requestPath: false,
      path: defaultPath,
      logger: logger,
    );

    when(() => logger.progress(any())).thenReturn(_MockProgress());
  });

  group('handle file test', () {
    test('reads pubspec.yaml file from path', () async {
      final data = await handler.readFile();

      verify(() => logger.progress('Reading file')).called(1);

      expect(data, isA<YamlMap>());
      expect(handler.getPath(), defaultPath);
    });

    test('reads pubspec.yaml file from path set by user', () async {
      handler = handler.copyWith(path: 'fake.yaml');
      final data = await handler.readFile();

      verify(() => logger.progress('Reading file')).called(1);

      expect(data, isA<YamlMap>());
      expect(handler.getPath(), 'fake.yaml');
    });

    test(
      'reads pubspec.yaml file from path provided by user in prompt',
      () async {
        handler = handler.copyWith(requestPath: true);

        when(
          () => logger.prompt(
            'Please enter the path to file:',
            defaultValue: any(
              named: 'defaultValue',
            ),
          ),
        ).thenReturn(testpath);

        final data = await handler.readFile();

        verify(() => logger.progress('Reading file')).called(1);

        expect(data, isA<YamlMap>());
        expect(handler.getPath(), testpath);
      },
    );

    test('throws error if path provided is not absolute', () async {
      handler = handler.copyWith(requestPath: true);

      when(
        () => logger.prompt(
          'Please enter the path to file:',
          defaultValue: any(
            named: 'defaultValue',
          ),
        ),
      ).thenReturn(wrongPath);

      final data = handler.readFile();

      verify(() => logger.progress('Reading file')).called(1);

      expect(() async => data, throwsA(isException));
    });
  });
}
