import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _FakeVersionValidator with ValidateVersion {}

void main() {
  late Logger logger;
  late _FakeVersionValidator validator;

  const version = '1.1.1';
  const prerelease = 'test';
  const build = 'jacked';

  setUp(() {
    logger = _MockLogger();
    validator = _FakeVersionValidator();

    when(() => logger.progress(any())).thenReturn(_MockProgress());
  });

  group('validate versions', () {
    test('returns version passed if valid', () async {
      final validatedVersion = await validator.validateVersion(
        logger: logger,
        version: version,
      );

      verify(() => logger.progress('Checking version number')).called(1);

      expect(validatedVersion, version);
    });
  });

  group('prompts for version', () {
    test('returns custom version when version is null', () async {
      // Reject base version
      when(
        () => logger.confirm(
          any(),
          defaultValue: any(
            named: 'defaultValue',
          ),
        ),
      ).thenReturn(false);

      // Add default version used for testing as version desired
      when(
        () => logger.prompt(
          'Enter version number : ',
          defaultValue: any(
            named: 'defaultValue',
          ),
        ),
      ).thenReturn(version);

      final validatedVersion = await validator.validateVersion(
        logger: logger,
        version: null,
      );

      verify(() => logger.progress('Checking version number')).called(1);

      expect(validatedVersion, version);
    });

    test('adds custom version when version is invalid', () async {
      // Reject base version
      when(
        () => logger.confirm(
          any(),
          defaultValue: any(
            named: 'defaultValue',
          ),
        ),
      ).thenReturn(false);

      // Add default version used for testing as version desired
      when(
        () => logger.prompt(
          'Enter version number : ',
          defaultValue: any(
            named: 'defaultValue',
          ),
        ),
      ).thenReturn(version);

      final validatedVersion = await validator.validateVersion(
        logger: logger,
        version: '1.1',
      );

      verify(() => logger.progress('Checking version number')).called(1);

      expect(validatedVersion, version);
    });

    test(
      'adds base version and adds custom prerelease & build info',
      () async {
        const expectedVersion = '0.0.0-$prerelease+$build';

        // Reject base version
        when(
          () => logger.confirm(
            any(),
            defaultValue: any(
              named: 'defaultValue',
            ),
          ),
        ).thenReturn(true);

        // Add default prerelease & build as desired
        when(
          () => logger.prompt(
            'Enter prerelease info : ',
            defaultValue: any(
              named: 'defaultValue',
            ),
          ),
        ).thenReturn(prerelease);

        when(
          () => logger.prompt(
            'Enter build number : ',
            defaultValue: any(
              named: 'defaultValue',
            ),
          ),
        ).thenReturn(build);

        final validatedVersion = await validator.validateVersion(
          logger: logger,
          version: null,
        );

        verify(() => logger.progress('Checking version number')).called(1);

        expect(validatedVersion, expectedVersion);
      },
    );
  });
}
