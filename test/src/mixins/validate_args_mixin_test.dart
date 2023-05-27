import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _FakeArgsValidator with ValidatePreppedArgs {}

class _MockLogger extends Mock implements Logger {}

void main() {
  late _FakeArgsValidator validator;
  late Logger logger;

  setUp(() {
    validator = _FakeArgsValidator();
    logger = _MockLogger();
  });

  group('basic errors with no set path', () {
    test('returns error when no args are passed', () async {
      const baseError = 'Missing arguments';
      const verboseError = 'No arguments found';

      final invalidReason = await validator.validateArgs(
        [],
        userSetPath: false,
        logger: logger,
      );

      expect(invalidReason, isNotNull);
      expect(invalidReason!.key, baseError);
      expect(invalidReason.value, verboseError);
    });

    test('returns error when undefined flags are passed', () async {
      const undefinedArg = ['undefined-arg'];
      const baseError = 'Invalid arguments';
      const verboseError = 'undefined-arg is not a defined flag';

      final invalidReason = await validator.validateArgs(
        undefinedArg,
        userSetPath: false,
        logger: logger,
      );

      expect(invalidReason, isNotNull);
      expect(invalidReason!.key, baseError);
      expect(invalidReason.value, verboseError);
    });

    test('returns error when flags are duplicated', () async {
      const duplicatedArgs = ['major', 'major', 'name', 'yaml-version'];
      const baseError = 'Duplicate flags';
      const verboseError = 'Found repeated flags:\nmajor -> 2\n';

      final invalidReason = await validator.validateArgs(
        duplicatedArgs,
        userSetPath: false,
        logger: logger,
      );

      expect(invalidReason, isNotNull);
      expect(invalidReason!.key, baseError);
      expect(invalidReason.value, verboseError);
    });
  });

  group('modify command errors', () {
    test('returns error when action flag is not first', () async {
      const args = ['major', 'bump'];
      const baseError = 'Wrong flag sequence';
      final verboseError =
          "${validator.actions.join(', ')} flags should come first";

      final invalidReason = await validator.validateArgs(
        args,
        isModify: true,
        userSetPath: false,
        logger: logger,
      );

      expect(invalidReason, isNotNull);
      expect(invalidReason!.key, baseError);
      expect(invalidReason.value, verboseError);
    });

    test('returns error when no targer flag is present', () async {
      const args = ['bump', 'with-path'];
      const baseError = 'Wrong flag sequence';
      final verboseError =
          // ignore: lines_longer_than_80_chars
          "Command should have at least one of ${validator.targets.take(4).join(', ')} flags";

      final invalidReason = await validator.validateArgs(
        args,
        isModify: true,
        userSetPath: false,
        logger: logger,
      );

      expect(invalidReason, isNotNull);
      expect(invalidReason!.key, baseError);
      expect(invalidReason.value, verboseError);
    });
  });

  group('no errors', () {
    test(
      'returns no errors when valid args are passed with no set path',
      () async {
        const validArgs = ['name', 'major', 'bump', 'yaml-version'];

        final invalidReason = await validator.validateArgs(
          validArgs,
          userSetPath: false,
          logger: logger,
        );

        expect(invalidReason, isNull);
      },
    );

    test("warns and removes 'with-path' flag when path is set", () async {
      const validArgs = ['name', 'major', 'bump', 'yaml-version', 'with-path'];

      final invalidReason = await validator.validateArgs(
        validArgs,
        userSetPath: true,
        logger: logger,
      );

      verify(
        () => logger.warn('Duplicate flags were found when path was set'),
      ).called(1);

      expect(invalidReason, isNull);
    });

    test(
      "warns and removes duplicate 'set-path' flag when path is set",
      () async {
        const validArgs = ['name', 'major', 'bump', 'yaml-version', 'set-path'];

        final invalidReason = await validator.validateArgs(
          validArgs,
          userSetPath: true,
          logger: logger,
        );

        verify(
          () => logger.warn(
            'Duplicate flags were found when path was set',
          ),
        ).called(1);

        expect(invalidReason, isNull);
      },
    );
  });
}
