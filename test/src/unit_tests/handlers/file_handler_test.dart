import 'package:magical_version_bump/src/core/handlers/file_handler/file_handler.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

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
    final handler = _FakeFileHandler()
      ..requestPath = requestPath
      ..fileLogger = logger;
    if (!requestPath) handler.files = getFileTypes([path]);
    return handler;
  }

  _FakeFileHandler copyWith({
    String? path,
    bool? requestPath,
  }) {
    return _FakeFileHandler.forTest(
      path: path ?? getPath(0),
      requestPath: requestPath ?? this.requestPath,
      logger: fileLogger,
    );
  }

  String getPath(int index) => getAllPaths()[index];

  List<String> getAllPaths() => files.keys.toList();
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

      expect(data, isA<FileOutput>());
      expect(handler.getPath(0), defaultPath);
    });

    test('reads pubspec.yaml file from path set by user', () async {
      handler = handler.copyWith(path: 'fake.yaml');
      final data = await handler.readFile();

      verify(() => logger.progress('Reading file')).called(1);

      expect(data, isA<FileOutput>());
      expect(handler.getPath(0), 'fake.yaml');
    });

    test(
      'reads pubspec.yaml file from path provided by user in prompt',
      () async {
        handler = handler.copyWith(requestPath: true);

        when(
          () => logger.prompt(
            'Please enter the path to file: ',
            defaultValue: any(
              named: 'defaultValue',
            ),
          ),
        ).thenReturn(testpath);

        final data = await handler.readFile();

        verify(() => logger.progress('Reading file')).called(1);

        expect(data, isA<FileOutput>());
        expect(handler.getPath(0), testpath);
      },
    );

    test(
      'read multiple files from paths provided by user in prompt',
      () async {
        handler = handler.copyWith(requestPath: true);

        final multiPaths = [defaultPath, testpath];

        when(
          () => logger.prompt(
            'Please enter all paths to files (use comma to separate): ',
            defaultValue: any(
              named: 'defaultValue',
            ),
          ),
        ).thenReturn(multiPaths.join(','));

        final data = await handler.readAll(multiple: true);

        verify(() => logger.progress('Reading files')).called(1);

        expect(data, isA<List<FileOutput>>());
        expect(handler.getAllPaths(), equals(multiPaths));
      },
    );

    test('throws error if path provided is not absolute', () async {
      handler = handler.copyWith(requestPath: true);

      when(
        () => logger.prompt(
          'Please enter the path to file: ',
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
