import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:test/test.dart';

class _FakeArgsValidator with ValidateArgs {}

void main() {
  late _FakeArgsValidator validator;

  const missingTargetsError = 'No targets found';
  var invalidTargetsError = '';

  setUp(() {
    validator = _FakeArgsValidator();

    invalidTargetsError =
        """Command should have at least one of ${validator.versionTargets.join(', ')} flags""";
  });

  group('validates and returns base error', () {
    test('when no targets are present', () {
      final error = validator.checkTargets([]);

      expect(error, missingTargetsError);
    });

    test('when invalid targets are present', () {
      final error = validator.checkTargets(['undefined']);

      expect(error, invalidTargetsError);
    });
  });
}
