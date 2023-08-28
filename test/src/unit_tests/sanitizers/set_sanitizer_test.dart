import 'package:args/args.dart';
import 'package:magical_version_bump/src/core/arg_sanitizers/arg_sanitizer.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

void main() {
  late SetArgumentSanitizer sanitizer;
  late ArgParser argParser;

  final nodesAndValues = <String, String>{
    'name': 'Gym Bro',
    'description': 'No cramps no gain',
    'homepage': 'Local gym',
    'repository': 'atp-chains.net',
    'issue_tracker': 'muscles.net',
    'documentation': 'fellow gym bro',
  };

  setUp(() {
    argParser = ArgParser()
      ..addOption(
        'name',
      )
      ..addOption(
        'description',
      )
      ..addOption(
        'homepage',
      )
      ..addOption(
        'repository',
      )
      ..addOption(
        'issue_tracker',
      )
      ..addOption(
        'documentation',
      )
      ..addMultiOption(
        'key',
      )
      ..addMultiOption(
        'value',
      );
  });

  group('preps args', () {
    test('when valid args are parsed', () {
      final args = nodesAndValues.entries.fold(
        <String>[],
        (previousValue, element) {
          previousValue.addAll(['--${element.key}', element.value]);
          return previousValue;
        },
      )..addAll(['--key', 'gym key', '--value', 'open gym']);

      sanitizer = setUpSanitizer(
        SanitizerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentSanitizer;

      final preppedArgs = sanitizer.prepArgs();

      final matcher = <String, String>{
        ...nodesAndValues,
        'gym key': 'open gym',
      };

      expect(preppedArgs, equals(matcher));
    });
  });

  group('validate args', () {
    test('returns error when no args are passed', () {
      sanitizer = setUpSanitizer(
        SanitizerType.setter,
        argParser: argParser,
        args: [],
      ) as SetArgumentSanitizer;

      final validatedArgs = sanitizer.customValidate(didSetVersion: false);

      expect(validatedArgs.isValid, false);
      expect(validatedArgs.reason, isNotNull);
      expect(validatedArgs.reason!.key, 'Missing arguments');
      expect(validatedArgs.reason!.value, 'Arguments cannot be empty or null');
      expect(validatedArgs.nodesAndValues, isNull);
    });

    test('returns prepped args with valid args parsed', () {
      sanitizer = setUpSanitizer(
        SanitizerType.setter,
        argParser: argParser,
        args: ['--key', 'gym key', '--value', 'open gym'],
      ) as SetArgumentSanitizer;

      final validatedArgs = sanitizer.customValidate(didSetVersion: false);

      expect(validatedArgs.isValid, true);
      expect(validatedArgs.reason, isNull);
      expect(validatedArgs.nodesAndValues, isNotNull);
      expect(validatedArgs.nodesAndValues, equals({'gym key': 'open gym'}));
    });
  });
}
