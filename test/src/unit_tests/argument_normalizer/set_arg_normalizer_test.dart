import 'package:args/args.dart';
import 'package:magical_version_bump/src/core/argument_normalizers/arg_normalizer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

void main() {
  late SetArgumentsNormalizer argsChecker;
  late ArgParser argParser;

  setUp(() {
    argParser = setUpArgParser();
  });

  group('parses dictionaries to be overwritten', () {
    test('when single key and value are passed in', () async {
      final args = ['--dictionary', 'test=1'];

      final expectedDictionary = (
        rootKeys: ['test'],
        data: '1',
        updateMode: UpdateMode.overwrite,
      );

      argsChecker = setUpSanitizer(
        ArgCheckerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsNormalizer;

      final (dictionaries, _) = argsChecker.prepArgs();

      expect(dictionaries.length, 1);
      expect(
        dictionaries.first.updateMode,
        equals(expectedDictionary.updateMode),
      );
      expect(
        dictionaries.first.rootKeys,
        equals(expectedDictionary.rootKeys),
      );
      expect(dictionaries.first.data, expectedDictionary.data);
    });

    test('when multiple keys and list of values are passed in', () async {
      final args = ['--dictionary', 'test,test2=1,2'];

      final expectedDictionary = (
        rootKeys: ['test', 'test2'],
        updateMode: UpdateMode.overwrite,
        data: ['1', '2'],
      );

      argsChecker = setUpSanitizer(
        ArgCheckerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsNormalizer;

      final (dictionaries, _) = argsChecker.prepArgs();

      expect(dictionaries.length, 1);
      expect(
        dictionaries.first.updateMode,
        equals(expectedDictionary.updateMode),
      );
      expect(
        dictionaries.first.rootKeys,
        equals(expectedDictionary.rootKeys),
      );
      expect(
        dictionaries.first.data,
        equals(expectedDictionary.data),
      );
    });

    test('when multiple keys and map of values are passed in', () async {
      final args = ['--dictionary', 'test,test2=1>2'];

      final expectedDictionary = (
        rootKeys: ['test', 'test2'],
        updateMode: UpdateMode.overwrite,
        data: {'1': '2'},
      );

      argsChecker = setUpSanitizer(
        ArgCheckerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsNormalizer;

      final (dictionaries, _) = argsChecker.prepArgs();

      expect(dictionaries.length, 1);
      expect(
        dictionaries.first.updateMode,
        equals(expectedDictionary.updateMode),
      );
      expect(
        dictionaries.first.rootKeys,
        equals(expectedDictionary.rootKeys),
      );
      expect(
        dictionaries.first.data,
        equals(expectedDictionary.data),
      );
    });
  });

  group('parses dictionaries to be append to', () {
    test('when single key and value are passed in', () async {
      final args = ['--add', 'test=1'];

      final expectedDictionary = (
        rootKeys: ['test'],
        updateMode: UpdateMode.append,
        data: '1',
      );

      argsChecker = setUpSanitizer(
        ArgCheckerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsNormalizer;

      final (dictionaries, _) = argsChecker.prepArgs();

      expect(dictionaries.length, 1);
      expect(
        dictionaries.first.updateMode,
        equals(expectedDictionary.updateMode),
      );
      expect(
        dictionaries.first.rootKeys,
        equals(expectedDictionary.rootKeys),
      );
      expect(dictionaries.first.data, expectedDictionary.data);
    });

    test('when multiple keys and list of values are passed in', () async {
      final args = ['--add', 'test,test2=1,2'];

      final expectedDictionary = (
        rootKeys: ['test', 'test2'],
        updateMode: UpdateMode.append,
        data: ['1', '2'],
      );

      argsChecker = setUpSanitizer(
        ArgCheckerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsNormalizer;

      final (dictionaries, _) = argsChecker.prepArgs();

      expect(dictionaries.length, 1);
      expect(
        dictionaries.first.updateMode,
        equals(expectedDictionary.updateMode),
      );
      expect(
        dictionaries.first.rootKeys,
        equals(expectedDictionary.rootKeys),
      );
      expect(
        dictionaries.first.data,
        equals(expectedDictionary.data),
      );
    });

    test('when multiple keys and map of values are passed in', () async {
      final args = ['--add', 'test,test2=1>2'];

      final expectedDictionary = (
        rootKeys: ['test', 'test2'],
        updateMode: UpdateMode.append,
        data: {'1': '2'},
      );

      argsChecker = setUpSanitizer(
        ArgCheckerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsNormalizer;

      final (dictionaries, _) = argsChecker.prepArgs();

      expect(dictionaries.length, 1);
      expect(
        dictionaries.first.updateMode,
        equals(expectedDictionary.updateMode),
      );
      expect(
        dictionaries.first.rootKeys,
        equals(expectedDictionary.rootKeys),
      );
      expect(
        dictionaries.first.data,
        equals(expectedDictionary.data),
      );
    });

    test('when only version is passed in args', () async {
      final args = [
        '--set-version',
        '10.10.10',
        '--set-prerelease',
        'deca',
        '--set-build',
        '10',
      ];

      argsChecker = setUpSanitizer(
        ArgCheckerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsNormalizer;

      final (dictionaries, versionModifiers) = argsChecker.prepArgs();

      expect(dictionaries.isEmpty, true);
      expect(versionModifiers.version, '10.10.10');
      expect(versionModifiers.prerelease, 'deca');
      expect(versionModifiers.build, '10');
    });
  });

  group('validate args', () {
    test('returns error when no args are passed', () {
      argsChecker = setUpSanitizer(
        ArgCheckerType.setter,
        argParser: argParser,
        args: [],
      ) as SetArgumentsNormalizer;

      final validatedArgs = argsChecker.validateArgs();

      expect(validatedArgs.isValid, false);
      expect(validatedArgs.reason, isNotNull);
      expect(validatedArgs.reason!.key, 'Missing arguments');
      expect(validatedArgs.reason!.value, 'Arguments cannot be empty or null');
    });
  });
}
