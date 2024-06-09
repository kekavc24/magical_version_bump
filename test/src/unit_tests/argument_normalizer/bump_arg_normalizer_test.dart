import 'package:args/args.dart';
import 'package:magical_version_bump/src/core/argument_normalizers/arg_normalizer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

void main() {
  late BumpArgumentsNormalizer argsChecker;
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
      ) as BumpArgumentsNormalizer;

      final (modifiers, targets) = argsChecker.prepArgs();

      expect(modifiers.strategy, ModifyStrategy.relative);
      expect(targets, equals(['major', 'build-number']));
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
      ) as BumpArgumentsNormalizer;

      final (modifiers, targets) = argsChecker.prepArgs();

      expect(modifiers.strategy, ModifyStrategy.absolute);
      expect(targets, equals(['major', 'minor', 'patch', 'build-number']));
    });
  });

  group('validate args', () {
    test('returns error when args are not present', () {
      argsChecker = setUpSanitizer(
        ArgCheckerType.bump,
        argParser: argParser,
        args: [],
      ) as BumpArgumentsNormalizer;

      final (_, reason) = argsChecker.validateArgs();

      expect(reason, isNotNull);
      expect(reason!.key, 'Missing arguments');
      expect(reason.value, 'Arguments cannot be empty or null');
    });

    test('returns error when targets are empty', () {
      final args = <String>['--strategy', 'relative'];

      argsChecker = setUpSanitizer(
        ArgCheckerType.bump,
        argParser: argParser,
        args: args,
      ) as BumpArgumentsNormalizer;

      final (_, reason) = argsChecker.validateArgs();

      expect(reason, isNotNull);
      expect(reason!.key, 'Invalid targets');
      expect(reason.value, error);
    });
  });
}
