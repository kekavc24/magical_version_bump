import 'package:args/args.dart';
import 'package:magical_version_bump/src/core/argument_checkers/arg_checker.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

void main() {
  late SetArgumentsChecker sanitizer;
  late ArgParser argParser;

  setUp(() {
    argParser = ArgParser()
      ..addMultiOption(
        'dictionary',
        splitCommas: false,
      )
      ..addMultiOption(
        'add',
        splitCommas: false,
      );
  });

  group('parses dictionaries to be overwritten', () {
    test('when single key and value are passed in', () {
      final args = ['--dictionary', 'test=1'];

      final expectedDictionary = (
        rootKeys: ['test'],
        append: false,
        data: '1',
      );

      sanitizer = setUpSanitizer(
        SanitizerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsChecker;

      final preppedArgs = sanitizer.prepArgs();

      expect(preppedArgs.length, 1);
      expect(preppedArgs.first.append, expectedDictionary.append);
      expect(preppedArgs.first.rootKeys, equals(expectedDictionary.rootKeys));
      expect(preppedArgs.first.data, expectedDictionary.data);
    });

    test('when multiple keys and list of values are passed in', () {
      final args = ['--dictionary', 'test|test2=1,2'];

      final expectedDictionary = (
        rootKeys: ['test', 'test2'],
        append: false,
        data: ['1', '2'],
      );

      sanitizer = setUpSanitizer(
        SanitizerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsChecker;

      final preppedArgs = sanitizer.prepArgs();

      expect(preppedArgs.length, 1);
      expect(preppedArgs.first.append, expectedDictionary.append);
      expect(preppedArgs.first.rootKeys, equals(expectedDictionary.rootKeys));
      expect(preppedArgs.first.data, equals(expectedDictionary.data));
    });

    test('when multiple keys and map of values are passed in', () {
      final args = ['--dictionary', 'test|test2=1->2'];

      final expectedDictionary = (
        rootKeys: ['test', 'test2'],
        append: false,
        data: {'1': '2'},
      );

      sanitizer = setUpSanitizer(
        SanitizerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsChecker;

      final preppedArgs = sanitizer.prepArgs();

      expect(preppedArgs.length, 1);
      expect(preppedArgs.first.append, expectedDictionary.append);
      expect(preppedArgs.first.rootKeys, equals(expectedDictionary.rootKeys));
      expect(preppedArgs.first.data, equals(expectedDictionary.data));
    });
  });

  group('parses dictionaries to be append to', () {
    test('when single key and value are passed in', () {
      final args = ['--add', 'test=1'];

      final expectedDictionary = (
        rootKeys: ['test'],
        append: true,
        data: '1',
      );

      sanitizer = setUpSanitizer(
        SanitizerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsChecker;

      final preppedArgs = sanitizer.prepArgs();

      expect(preppedArgs.length, 1);
      expect(preppedArgs.first.append, expectedDictionary.append);
      expect(preppedArgs.first.rootKeys, equals(expectedDictionary.rootKeys));
      expect(preppedArgs.first.data, expectedDictionary.data);
    });

    test('when multiple keys and list of values are passed in', () {
      final args = ['--add', 'test|test2=1,2'];

      final expectedDictionary = (
        rootKeys: ['test', 'test2'],
        append: true,
        data: ['1', '2'],
      );

      sanitizer = setUpSanitizer(
        SanitizerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsChecker;

      final preppedArgs = sanitizer.prepArgs();

      expect(preppedArgs.length, 1);
      expect(preppedArgs.first.append, expectedDictionary.append);
      expect(preppedArgs.first.rootKeys, equals(expectedDictionary.rootKeys));
      expect(preppedArgs.first.data, equals(expectedDictionary.data));
    });

    test('when multiple keys and map of values are passed in', () {
      final args = ['--add', 'test|test2=1->2'];

      final expectedDictionary = (
        rootKeys: ['test', 'test2'],
        append: true,
        data: {'1': '2'},
      );

      sanitizer = setUpSanitizer(
        SanitizerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsChecker;

      final preppedArgs = sanitizer.prepArgs();

      expect(preppedArgs.length, 1);
      expect(preppedArgs.first.append, expectedDictionary.append);
      expect(preppedArgs.first.rootKeys, equals(expectedDictionary.rootKeys));
      expect(preppedArgs.first.data, equals(expectedDictionary.data));
    });
  });

  group('validate args', () {
    test('returns error when no args are passed', () {
      sanitizer = setUpSanitizer(
        SanitizerType.setter,
        argParser: argParser,
        args: [],
      ) as SetArgumentsChecker;

      final validatedArgs = sanitizer.customValidate(didSetVersion: false);

      expect(validatedArgs.isValid, false);
      expect(validatedArgs.reason, isNotNull);
      expect(validatedArgs.reason!.key, 'Missing arguments');
      expect(validatedArgs.reason!.value, 'Arguments cannot be empty or null');
      expect(validatedArgs.dictionaries, equals([]));
    });

    test('returns prepped args with valid args parsed', () {
      sanitizer = setUpSanitizer(
        SanitizerType.setter,
        argParser: argParser,
        args: [],
      ) as SetArgumentsChecker;

      final validatedArgs = sanitizer.customValidate(didSetVersion: true);

      expect(validatedArgs.isValid, true);
      expect(validatedArgs.reason, isNull);
      expect(validatedArgs.dictionaries, equals([]));
    });
  });
}
