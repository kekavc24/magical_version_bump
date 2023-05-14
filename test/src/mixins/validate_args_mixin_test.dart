import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:test/test.dart';

class _FakeArgsValidator with ValidatePreppedArgs {}

void main() {
  late _FakeArgsValidator validator;

  setUp(() => validator = _FakeArgsValidator());

  group('basic errors', () {
    test('returns error when no args are passed', () async {
      const baseError = 'Missing arguments';
      const verboseError = 'No arguments found';

      final invalidReason = await validator.validateArgs([], isModify: false);

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
        isModify: false,
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
        isModify: false,
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

      final invalidReason = await validator.validateArgs(args, isModify: true);

      expect(invalidReason, isNotNull);
      expect(invalidReason!.key, baseError);
      expect(invalidReason.value, verboseError);
    });
  });

  group('no errors', () {
    test('returns no errors when valid args are passed', () async {
      const validArgs = ['name', 'major', 'bump', 'yaml-version'];

      final invalidReason = await validator.validateArgs(
        validArgs,
        isModify: false,
      );

      expect(invalidReason, isNull);
    });
  });
}
