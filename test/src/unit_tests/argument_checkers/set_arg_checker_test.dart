import 'package:args/args.dart';
import 'package:magical_version_bump/src/core/argument_checkers/arg_checker.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

void main() {
  late SetArgumentsChecker argsChecker;
  late SetArgumentsChecker nullableChecker;
  late ArgParser argParser;

  setUp(() {
    argParser = setUpArgParser();

    nullableChecker = SetArgumentsChecker(argResults: null);
  });

  group('parses dictionaries to be overwritten', () {
    test('when single key and value are passed in', () {
      final args = ['--dictionary', 'test=1'];

      final expectedDictionary = (
        rootKeys: ['test'],
        append: false,
        data: '1',
      );

      argsChecker = setUpSanitizer(
        ArgCheckerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsChecker;

      final preppedArgs = argsChecker.prepArgs();

      expect(preppedArgs.dictionaries.length, 1);
      expect(preppedArgs.dictionaries.first.append, expectedDictionary.append);
      expect(
        preppedArgs.dictionaries.first.rootKeys,
        equals(expectedDictionary.rootKeys),
      );
      expect(preppedArgs.dictionaries.first.data, expectedDictionary.data);
    });

    test('when multiple keys and list of values are passed in', () {
      final args = ['--dictionary', 'test|test2=1,2'];

      final expectedDictionary = (
        rootKeys: ['test', 'test2'],
        append: false,
        data: ['1', '2'],
      );

      argsChecker = setUpSanitizer(
        ArgCheckerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsChecker;

      final preppedArgs = argsChecker.prepArgs();

      expect(preppedArgs.dictionaries.length, 1);
      expect(preppedArgs.dictionaries.first.append, expectedDictionary.append);
      expect(
        preppedArgs.dictionaries.first.rootKeys,
        equals(expectedDictionary.rootKeys),
      );
      expect(
        preppedArgs.dictionaries.first.data,
        equals(expectedDictionary.data),
      );
    });

    test('when multiple keys and map of values are passed in', () {
      final args = ['--dictionary', 'test|test2=1->2'];

      final expectedDictionary = (
        rootKeys: ['test', 'test2'],
        append: false,
        data: {'1': '2'},
      );

      argsChecker = setUpSanitizer(
        ArgCheckerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsChecker;

      final preppedArgs = argsChecker.prepArgs();

      expect(preppedArgs.dictionaries.length, 1);
      expect(preppedArgs.dictionaries.first.append, expectedDictionary.append);
      expect(
        preppedArgs.dictionaries.first.rootKeys,
        equals(expectedDictionary.rootKeys),
      );
      expect(
        preppedArgs.dictionaries.first.data,
        equals(expectedDictionary.data),
      );
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

      argsChecker = setUpSanitizer(
        ArgCheckerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsChecker;

      final preppedArgs = argsChecker.prepArgs();

      expect(preppedArgs.dictionaries.length, 1);
      expect(preppedArgs.dictionaries.first.append, expectedDictionary.append);
      expect(
        preppedArgs.dictionaries.first.rootKeys,
        equals(expectedDictionary.rootKeys),
      );
      expect(preppedArgs.dictionaries.first.data, expectedDictionary.data);
    });

    test('when multiple keys and list of values are passed in', () {
      final args = ['--add', 'test|test2=1,2'];

      final expectedDictionary = (
        rootKeys: ['test', 'test2'],
        append: true,
        data: ['1', '2'],
      );

      argsChecker = setUpSanitizer(
        ArgCheckerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsChecker;

      final preppedArgs = argsChecker.prepArgs();

      expect(preppedArgs.dictionaries.length, 1);
      expect(preppedArgs.dictionaries.first.append, expectedDictionary.append);
      expect(
        preppedArgs.dictionaries.first.rootKeys,
        equals(expectedDictionary.rootKeys),
      );
      expect(
        preppedArgs.dictionaries.first.data,
        equals(expectedDictionary.data),
      );
    });

    test('when multiple keys and map of values are passed in', () {
      final args = ['--add', 'test|test2=1->2'];

      final expectedDictionary = (
        rootKeys: ['test', 'test2'],
        append: true,
        data: {'1': '2'},
      );

      argsChecker = setUpSanitizer(
        ArgCheckerType.setter,
        argParser: argParser,
        args: args,
      ) as SetArgumentsChecker;

      final preppedArgs = argsChecker.prepArgs();

      expect(preppedArgs.dictionaries.length, 1);
      expect(preppedArgs.dictionaries.first.append, expectedDictionary.append);
      expect(
        preppedArgs.dictionaries.first.rootKeys,
        equals(expectedDictionary.rootKeys),
      );
      expect(
        preppedArgs.dictionaries.first.data,
        equals(expectedDictionary.data),
      );
    });

    test('when only version is passed in args', () {
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
      ) as SetArgumentsChecker;

      final preppedArgs = argsChecker.prepArgs();

      expect(preppedArgs.dictionaries.isEmpty, true);
      expect(preppedArgs.modifiers.version, '10.10.10');
      expect(preppedArgs.modifiers.prerelease, 'deca');
      expect(preppedArgs.modifiers.build, '10');
    });
  });

  group('validate args', () {
    test('returns error when no args are passed', () {
      argsChecker = setUpSanitizer(
        ArgCheckerType.setter,
        argParser: argParser,
        args: [],
      ) as SetArgumentsChecker;

      final validatedArgs = argsChecker.validateArgs();

      expect(validatedArgs.isValid, false);
      expect(validatedArgs.reason, isNotNull);
      expect(validatedArgs.reason!.key, 'Missing arguments');
      expect(validatedArgs.reason!.value, 'Arguments cannot be empty or null');
    });
  });

  group('dictionary', () {
    test('extracts key and value', () {
      final dictionary = nullableChecker.extractDictionary(
        'testKey=testValue',
        append: false,
      );

      expect(dictionary.rootKeys, equals(['testKey']));
      expect(dictionary.data, isA<String>());
      expect(dictionary.data, 'testValue');
    });

    test('extracts multiple keys and value', () {
      final dictionary = nullableChecker.extractDictionary(
        'testKey|anotherKey=testValue',
        append: false,
      );

      expect(dictionary.rootKeys, equals(['testKey', 'anotherKey']));
      expect(dictionary.data, isA<String>());
      expect(dictionary.data, 'testValue');
    });

    test('extracts key and multiple values', () {
      final dictionary = nullableChecker.extractDictionary(
        'testKey=testValue,anotherValue',
        append: false,
      );

      expect(dictionary.rootKeys, equals(['testKey']));
      expect(dictionary.data, isList);
      expect(dictionary.data, equals(['testValue', 'anotherValue']));
    });

    test('extracts key and multiple values, retains non-empty', () {
      final dictionary = nullableChecker.extractDictionary(
        'testKey=testValue,anotherValue,',
        append: false,
      );

      expect(dictionary.rootKeys, equals(['testKey']));
      expect(dictionary.data, isList);
      expect(dictionary.data, equals(['testValue', 'anotherValue']));
    });

    test('extracts multiple keys and values', () {
      final dictionary = nullableChecker.extractDictionary(
        'testKey|anotherKey=testValue,anotherValue',
        append: false,
      );

      expect(dictionary.rootKeys, equals(['testKey', 'anotherKey']));
      expect(dictionary.data, isList);
      expect(dictionary.data, equals(['testValue', 'anotherValue']));
    });

    test('extracts key and mapped values', () {
      final dictionary = nullableChecker.extractDictionary(
        'testKey=testMapKey->testMapValue',
        append: false,
      );

      expect(dictionary.rootKeys, equals(['testKey']));
      expect(dictionary.data, isMap);
      expect(
        dictionary.data,
        equals({'testMapKey': 'testMapValue'}),
      );
    });

    test('extracts strings and mapped values as list of values', () {
      final dictionary = nullableChecker.extractDictionary(
        'key=value,mapKey->mapValue',
        append: false,
      );

      expect(dictionary.rootKeys, equals(['key']));
      expect(dictionary.data, isList);
      expect(
        dictionary.data,
        equals([
          'value',
          {'mapKey': 'mapValue'},
        ]),
      );
    });

    test('extracts key and mapped values, sets empty pairs to null', () {
      final dictionary = nullableChecker.extractDictionary(
        'testKey=testMapKey->',
        append: false,
      );

      expect(dictionary.rootKeys, equals(['testKey']));
      expect(dictionary.data, isMap);
      expect(
        dictionary.data,
        equals({'testMapKey': 'null'}),
      );
    });

    test('extracts multiple keys and mapped values', () {
      final dictionary = nullableChecker.extractDictionary(
        '''testKey|anotherKey=testMapKey->testMapValue,otherMapKey->otherMapValue''',
        append: false,
      );

      final expectedMappedValues = <String, String>{
        'testMapKey': 'testMapValue',
        'otherMapKey': 'otherMapValue',
      };

      expect(dictionary.rootKeys, equals(['testKey', 'anotherKey']));
      expect(dictionary.data, isMap);
      expect(dictionary.data, equals(expectedMappedValues));
    });

    test('throws error when parsed value is empty', () {
      expect(
        () => nullableChecker.extractDictionary('', append: false),
        throwsViolation('The root key cannot be empty/null'),
      );
    });

    test('throws error when parsed value has no key-value pair', () {
      const valueWithOnePair = 'key=';
      const valueWithBlanks = '=';

      expect(
        () => nullableChecker.extractDictionary(
          valueWithBlanks,
          append: false,
        ),
        throwsViolation(
          'Invalid keys and value pair at "$valueWithBlanks"',
        ),
      );

      expect(
        () => nullableChecker.extractDictionary(
          valueWithOnePair,
          append: false,
        ),
        throwsViolation(
          'Invalid keys and value pair at "$valueWithOnePair"',
        ),
      );
    });
  });
}
