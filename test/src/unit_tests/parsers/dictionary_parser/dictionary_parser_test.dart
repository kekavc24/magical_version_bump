import 'package:magical_version_bump/src/core/parsers/dictionary_parser/dictionary_parser.dart';
import 'package:test/test.dart';

import '../../../../helpers/helpers.dart';

void main() {
  final dictionaryParser = DictionaryParser();

  group('parses dictionary', () {
    test('extracts key and value', () async {
      final dictionary = dictionaryParser.parse(
        'testKey=testValue',
        0,
      );

      expect(dictionary.rootKeys, equals(['testKey']));
      expect(dictionary.data, 'testValue');
    });

    test('extracts multiple keys and value', () async {
      final dictionary = dictionaryParser.parse(
        'testKey,anotherKey=testValue',
        0,
      );

      expect(dictionary.rootKeys, equals(['testKey', 'anotherKey']));
      expect(dictionary.data, 'testValue');
    });

    test('extracts key and multiple values', () async {
      final dictionary = dictionaryParser.parse(
        'testKey=testValue,anotherValue',
        0,
      );

      expect(dictionary.rootKeys, equals(['testKey']));
      expect(dictionary.data, equals(['testValue', 'anotherValue']));
    });

    test('extracts key and multiple values, retains non-empty', () async {
      final dictionary = dictionaryParser.parse(
        'testKey=testValue,anotherValue,',
        0,
      );

      expect(dictionary.rootKeys, equals(['testKey']));
      expect(dictionary.data, equals(['testValue', 'anotherValue']));
    });

    test('extracts multiple keys and values', () async {
      final dictionary = dictionaryParser.parse(
        'testKey,anotherKey=testValue,anotherValue',
        0,
      );

      expect(dictionary.rootKeys, equals(['testKey', 'anotherKey']));
      expect(dictionary.data, equals(['testValue', 'anotherValue']));
    });

    test('extracts key and mapped values', () async {
      final dictionary = dictionaryParser.parse(
        'testKey=testMapKey>testMapValue',
        0,
      );

      expect(dictionary.rootKeys, equals(['testKey']));
      expect(
        dictionary.data,
        equals({'testMapKey': 'testMapValue'}),
      );
    });

    test('extracts strings and mapped values as list of values', () async {
      final dictionary = dictionaryParser.parse(
        'key=value,mapKey>mapValue',
        0,
      );

      expect(dictionary.rootKeys, equals(['key']));
      expect(
        dictionary.data,
        equals([
          'value',
          {'mapKey': 'mapValue'},
        ]),
      );
    });

    test(
      'extracts key and values, ignores map delimiter if pair is missing',
      () async {
        final dictionary = dictionaryParser.parse(
          'testKey=testMapKey>',
          0,
        );

        expect(dictionary.rootKeys, equals(['testKey']));
        expect(
          dictionary.data,
          equals('testMapKey'),
        );
      },
    );

    test('extracts multiple keys and mapped values', () async {
      final dictionary = dictionaryParser.parse(
        '''testKey,anotherKey=testMapKey>testMapValue,otherMapKey>otherMapValue''',
        0,
      );

      final expectedMappedValues = <String, String>{
        'testMapKey': 'testMapValue',
        'otherMapKey': 'otherMapValue',
      };

      expect(dictionary.rootKeys, equals(['testKey', 'anotherKey']));
      expect(dictionary.data, equals(expectedMappedValues));
    });

    test('extracts & generates map for multi-key map in value', () async {
      final dictionary = dictionaryParser.parse(
        '''testKey=testMapKey>otherMapKey>otherMapValue''',
        0,
      );

      final expectedMappedValues = <String, dynamic>{
        'testMapKey': {'otherMapKey': 'otherMapValue'},
      };

      expect(dictionary.rootKeys, equals(['testKey']));
      expect(dictionary.data, equals(expectedMappedValues));
    });

    test(
      'extracts & generates map for multi-key map when value is null',
      () async {
        final dictionary = dictionaryParser.parse(
          '''testKey=testMapKey>otherMapKey>''',
          0,
        );

        final expectedMappedValues = <String, dynamic>{
          'testMapKey': {'otherMapKey': 'null'},
        };

        expect(dictionary.rootKeys, equals(['testKey']));
        expect(dictionary.data, equals(expectedMappedValues));
      },
    );

    test('extracts escaped delimiters used for either key/value', () async {
      final dictionary = dictionaryParser.parse(
        r'\,\,=\>\>',
        0,
      );

      expect(dictionary.rootKeys, equals([',,']));
      expect(dictionary.data, equals('>>'));
    });
  });

  group('throws exception', () {
    test('when input is empty', () {
      expect(
        () => dictionaryParser.parse('', 0),
        throwsCustomException(
          createDictParserMessage('', 'Input cannot be empty!'),
        ),
      );
    });

    test('when escaping but no characters are provided', () {
      const input = r'\';

      expect(
        () => dictionaryParser.parse(input, 0),
        throwsCustomException(
          createDictParserMessage(
            input,
            r'Expected an escaped character after "\"',
            position: -1,
          ),
        ),
      );
    });

    test('when no values are provided', () {
      const input = 'key=';

      expect(
        () => dictionaryParser.parse(input, 0),
        throwsCustomException(
          createDictParserMessage(
            input,
            'Expected at least one value but got nothing',
            position: -1,
          ),
        ),
      );
    });

    test('when no keys are provided', () {
      const input = '=value';

      expect(
        () => dictionaryParser.parse(input, 0),
        throwsCustomException(
          createDictParserMessage(
            input,
            'Expected a key but found the delimiter, "="',
          ),
        ),
      );
    });

    test('when multiple key delimiters are used without escaping', () {
      const input = 'key,,key';

      expect(
        () => dictionaryParser.parse(input, 0),
        throwsCustomException(
          createDictParserMessage(
            input,
            '''Expected a key but found the delimiter, ",". Consider escaping any key delimiter(s) used.''',
            position: 4,
          ),
        ),
      );
    });

    test('when value delimiters are used with keys', () {
      const input = 'key>key=value';

      expect(
        () => dictionaryParser.parse(input, 0),
        throwsCustomException(
          createDictParserMessage(
            input,
            '''Expected a key but found the delimiter, ">". Value delimiters not allowed!''',
            position: 3,
          ),
        ),
      );
    });

    test(
      'when value delimiters are used without providing at least one value',
      () {
        const input = 'key=,value';

        expect(
          () => dictionaryParser.parse(input, 0),
          throwsCustomException(
            createDictParserMessage(
              input,
              'Expected first value but found, ",". Consider escaping it',
              position: 4,
            ),
          ),
        );
      },
    );

    test('when multiple value delimiters are used without escaping', () {
      const input = 'key=value,>';

      expect(
        () => dictionaryParser.parse(input, 0),
        throwsCustomException(
          createDictParserMessage(
            input,
            'Expected a value but found, ">". Consider escaping it',
            position: 10,
          ),
        ),
      );
    });
  });
}
