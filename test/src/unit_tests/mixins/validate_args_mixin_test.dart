import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/core/mixins/command_mixins.dart';
import 'package:test/test.dart';

class _FakeArgsValidator with ValidatePreppedArgs {}

void main() {
  late _FakeArgsValidator validator;
  late ListEquality<String> listEquality;

  setUp(() {
    validator = _FakeArgsValidator();
    listEquality = const ListEquality<String>();
  });

  group('validates and returns base error', () {
    test('returns undefined flags', () {
      final args = ['bump', 'undefined'];

      final undefinedFlags = validator.checkForUndefinedFlags(args);

      expect(listEquality.equals(['undefined'], undefinedFlags), true);
    });

    test('returns error when action flag is not first', () {
      const args = ['major', 'bump'];
      final error = "${validator.actions.join(', ')} flags should come first";

      final returnedError = validator.checkModifyFlags(args);

      expect(returnedError, error);
    });

    test('returns error when bump and dump are used together', () {
      const args = ['dump', 'bump'];
      const error = 'bump and dump flags cannot be used together';

      final returnedError = validator.checkModifyFlags(args);

      expect(returnedError, error);
    });

    test('returns error when no target flag is passed in', () {
      const args = ['bump'];
      final error =
          """Command should have at least one of ${validator.targets.take(4).join(', ')} flags""";

      final returnedError = validator.checkModifyFlags(args);

      expect(returnedError, error);
    });

    test('returns error when flags are duplicated', () {
      const args = ['major', 'major', 'name', 'yaml-version'];
      const error = 'Found repeated flags:\nmajor -> 2\n';

      final returnedError = validator.checkForDuplicates(args);

      expect(returnedError, error);
    });
  });
}
