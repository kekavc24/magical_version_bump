import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/core/arg_sanitizers/arg_sanitizer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:test/test.dart';

void main() {
  late ModifyArgumentSanitizer modifySanitizer;
  late ChangeArgumentSanitizer changeSanitizer;
  late ListEquality<String> listEquality;

  setUp(() {
    modifySanitizer = ModifyArgumentSanitizer();
    changeSanitizer = ChangeArgumentSanitizer();
    listEquality = const ListEquality<String>();
  });

  group('preps modify commands args', () {
    test('preps args', () {
      final args = <String>['bump', 'major'];

      final prepData = modifySanitizer.prepArgs(args);

      expect(prepData.action, 'bump');
      expect(listEquality.equals(['major'], prepData.versionTargets), true);
      expect(prepData.strategy, ModifyStrategy.relative);
      expect(prepData.requestPath, false);
    });

    test('preps args and sets request path to true', () {
      final args = <String>['bump', 'major', 'with-path'];

      final prepData = modifySanitizer.prepArgs(args);

      expect(prepData.action, 'bump');
      expect(listEquality.equals(['major'], prepData.versionTargets), true);
      expect(prepData.strategy, ModifyStrategy.relative);
      expect(prepData.requestPath, true);
    });

    test('preps args and sets request path & absolute version to true', () {
      final args = <String>['bump', 'major', 'with-path', 'absolute'];

      final prepData = modifySanitizer.prepArgs(args);

      expect(prepData.action, 'bump');
      expect(listEquality.equals(['major'], prepData.versionTargets), true);
      expect(prepData.strategy, ModifyStrategy.absolute);
      expect(prepData.requestPath, true);
    });
  });

  group('preps change command args', () {
    test('preps args', () {
      final args = <String>['name=Test', 'version=1.1.1'];

      final prepped = args.fold(
        <String, String>{},
        (previousValue, element) {
          final split = element.split('=');
          previousValue.addAll({split.first: split.last});
          return previousValue;
        },
      );

      final argsAndValues = changeSanitizer.prepArgs(args);

      expect(
        listEquality.equals(argsAndValues.keys.toList(), prepped.keys.toList()),
        true,
      );
      expect(
        listEquality.equals(
          argsAndValues.values.toList(),
          prepped.values.toList(),
        ),
        true,
      );
    });
  });

  group('validates change and modify commands args correctly and', () {
    test('returns error when undefined flags are passed', () async {
      const undefinedArg = ['undefined-arg'];
      const baseError = 'Invalid arguments';
      const verboseError = 'undefined-arg is not a defined flag';

      final validatedArgs = changeSanitizer.validateArgs(
        undefinedArg,
      );

      expect(validatedArgs.isValid, false);
      expect(validatedArgs.reason, isNotNull);
      expect(validatedArgs.reason!.key, baseError);
      expect(validatedArgs.reason!.value, verboseError);
    });

    test('returns error when flags are duplicated', () async {
      const duplicatedArgs = ['major', 'major', 'name', 'yaml-version'];
      const baseError = 'Duplicate flags';
      const verboseError = 'Found repeated flags:\nmajor -> 2\n';

      final validatedArgs = changeSanitizer.validateArgs(
        duplicatedArgs,
      );

      expect(validatedArgs.isValid, false);
      expect(validatedArgs.reason, isNotNull);
      expect(validatedArgs.reason!.key, baseError);
      expect(validatedArgs.reason!.value, verboseError);
    });
  });

  group('validates modify command args correctly and', () {
    test('returns error when no args are passed in', () async {
      const baseError = 'Missing arguments';
      const verboseError = 'Additional arguments for this command are missing';

      final validatedArgs = modifySanitizer.customValidate(
        [],
      );

      expect(validatedArgs.isValid, false);
      expect(validatedArgs.reason, isNotNull);
      expect(validatedArgs.reason!.key, baseError);
      expect(validatedArgs.reason!.value, verboseError);
    });

    test('returns error when action flag is not first', () async {
      const args = ['major', 'bump'];
      const baseError = 'Wrong flag sequence';
      final verboseError =
          "${modifySanitizer.actions.join(', ')} flags should come first";

      final validatedArgs = modifySanitizer.customValidate(
        args,
      );

      expect(validatedArgs.isValid, false);
      expect(validatedArgs.reason, isNotNull);
      expect(validatedArgs.reason!.key, baseError);
      expect(validatedArgs.reason!.value, verboseError);
    });

    test('returns error when no targer flag is present', () async {
      const args = ['bump', 'with-path'];
      const baseError = 'Wrong flag sequence';
      final verboseError =
          """Command should have at least one of ${modifySanitizer.targets.take(4).join(', ')} flags""";

      final validatedArgs = modifySanitizer.customValidate(
        args,
      );

      expect(validatedArgs.isValid, false);
      expect(validatedArgs.reason, isNotNull);
      expect(validatedArgs.reason!.key, baseError);
      expect(validatedArgs.reason!.value, verboseError);
    });

    test('returns error when bump and dump are used together', () async {
      const args = ['dump', 'bump'];
      const baseError = 'Wrong flag sequence';
      const verboseError = 'bump and dump flags cannot be used together';

      final validatedArgs = modifySanitizer.customValidate(
        args,
      );

      expect(validatedArgs.isValid, false);
      expect(validatedArgs.reason, isNotNull);
      expect(validatedArgs.reason!.key, baseError);
      expect(validatedArgs.reason!.value, verboseError);
    });
  });
}
