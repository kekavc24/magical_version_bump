import 'package:args/args.dart';
import 'package:magical_version_bump/src/core/arg_sanitizers/arg_sanitizer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

void main() {
  late BumpArgumentSanitizer sanitizer;
  late ArgParser argParser;

  setUp(() {
    argParser = ArgParser()
      ..addMultiOption(
        'targets',
        allowed: ['major', 'minor', 'patch', 'build-number'],
      )
      ..addOption(
        'strategy',
        allowed: ['relative', 'absolute'],
      );
  });

  group('preps args', () {
    test('with relative modify strategy', () {
      final args = <String>[
        '--targets',
        'major,minor,patch,build-number',
        '--strategy',
        'relative',
      ];

      sanitizer = setUpSanitizer(
        SanitizerType.bump,
        argParser: argParser,
        args: args,
      ) as BumpArgumentSanitizer;

      final preppedArgs = sanitizer.prepArgs();

      expect(preppedArgs.strategy, ModifyStrategy.relative);
      expect(preppedArgs.targets, equals(['major', 'build-number']));
    });

    test('with absolute modify strategy', () {
      final args = <String>[
        '--targets',
        'major,minor,patch,build-number',
        '--strategy',
        'absolute',
      ];

      sanitizer = setUpSanitizer(
        SanitizerType.bump,
        argParser: argParser,
        args: args,
      ) as BumpArgumentSanitizer;

      final preppedArgs = sanitizer.prepArgs();

      expect(preppedArgs.strategy, ModifyStrategy.absolute);
      expect(
        preppedArgs.targets,
        equals(['major', 'minor', 'patch', 'build-number']),
      );
    });
  });

  group('validate args', () {
    test('returns error when args are not present', () {
      sanitizer = setUpSanitizer(
        SanitizerType.bump,
        argParser: argParser,
        args: [],
      ) as BumpArgumentSanitizer;

      final validatedArgs = sanitizer.customValidate();

      expect(validatedArgs.isValid, false);
      expect(validatedArgs.reason, isNotNull);
      expect(validatedArgs.reason!.key, 'Missing arguments');
      expect(validatedArgs.reason!.value, 'Arguments cannot be empty or null');
    });

    test('returns error when targets are empty', () {
      final args = <String>['--strategy', 'relative'];

      sanitizer = setUpSanitizer(
        SanitizerType.bump,
        argParser: argParser,
        args: args,
      ) as BumpArgumentSanitizer;

      final validatedArgs = sanitizer.customValidate();

      expect(validatedArgs.isValid, false);
      expect(validatedArgs.reason, isNotNull);
      expect(validatedArgs.reason!.key, 'Invalid targets');
      expect(validatedArgs.reason!.value, 'No targets found');
    });
  });
}
