import 'package:args/args.dart';
import 'package:magical_version_bump/src/core/argument_checkers/arg_checker.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

void main() {
  late BumpArgumentsChecker argsChecker;
  late ArgParser argParser;

  const error =
      '''You need to pass in a target i.e. major, minor, patch or build-number''';

  setUp(() {
    argParser = setUpArgParser();
  });

  group('preps args', () {
    test('with relative modify strategy', () {
      final args = <String>[
        '--targets',
        'major,minor,patch,build-number',
        '--strategy',
        'relative',
      ];

      argsChecker = setUpSanitizer(
        ArgCheckerType.bump,
        argParser: argParser,
        args: args,
      ) as BumpArgumentsChecker;

      final preppedArgs = argsChecker.prepArgs();

      expect(preppedArgs.modifiers.strategy, ModifyStrategy.relative);
      expect(preppedArgs.targets, equals(['major', 'build-number']));
    });

    test('with absolute modify strategy', () {
      final args = <String>[
        '--targets',
        'major,minor,patch,build-number',
        '--strategy',
        'absolute',
      ];

      argsChecker = setUpSanitizer(
        ArgCheckerType.bump,
        argParser: argParser,
        args: args,
      ) as BumpArgumentsChecker;

      final preppedArgs = argsChecker.prepArgs();

      expect(preppedArgs.modifiers.strategy, ModifyStrategy.absolute);
      expect(
        preppedArgs.targets,
        equals(['major', 'minor', 'patch', 'build-number']),
      );
    });
  });

  group('validate args', () {
    test('returns error when args are not present', () {
      argsChecker = setUpSanitizer(
        ArgCheckerType.bump,
        argParser: argParser,
        args: [],
      ) as BumpArgumentsChecker;

      final validatedArgs = argsChecker.validateArgs();

      expect(validatedArgs.isValid, false);
      expect(validatedArgs.reason, isNotNull);
      expect(validatedArgs.reason!.key, 'Missing arguments');
      expect(validatedArgs.reason!.value, 'Arguments cannot be empty or null');
    });

    test('returns error when targets are empty', () {
      final args = <String>['--strategy', 'relative'];

      argsChecker = setUpSanitizer(
        ArgCheckerType.bump,
        argParser: argParser,
        args: args,
      ) as BumpArgumentsChecker;

      final validatedArgs = argsChecker.validateArgs();

      expect(validatedArgs.isValid, false);
      expect(validatedArgs.reason, isNotNull);
      expect(validatedArgs.reason!.key, 'Invalid targets');
      expect(validatedArgs.reason!.value, error);
    });
  });
}
