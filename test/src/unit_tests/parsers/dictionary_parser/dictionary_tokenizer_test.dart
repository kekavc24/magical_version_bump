import 'package:magical_version_bump/src/core/parsers/dictionary_parser/dictionary_parser.dart';
import 'package:test/test.dart';

void main() {
  late DictionaryTokenizer tokenizer;

  void addTokenizerInput(String input) {
    tokenizer = DictionaryTokenizer.addInput(input);
  }

  group('generates token from char', () {
    setUpAll(() => addTokenizerInput('')); // All tests here don't need input

    test('when delimiters are passed in', () {
      final (escapeToken, _) = tokenizer.generateTokens(r'\');
      final (mapToken, _) = tokenizer.generateTokens('>');
      final (listToken, _) = tokenizer.generateTokens(',');
      final (kvToken, _) = tokenizer.generateTokens('=');

      expect(
        escapeToken,
        equals((token: r'\', tokenType: DictionaryTokenType.escapeDelimiter)),
      );
      expect(
        mapToken,
        equals((token: '>', tokenType: DictionaryTokenType.mapDelimiter)),
      );
      expect(
        listToken,
        equals((token: ',', tokenType: DictionaryTokenType.listDelimiter)),
      );
      expect(
        kvToken,
        equals((token: '=', tokenType: DictionaryTokenType.kvDelimiter)),
      );
    });

    test('when char is a non-delimiter and buffers it', () {
      final (token, _) = tokenizer.generateTokens('n');

      expect(
        token,
        equals((token: null, tokenType: DictionaryTokenType.none)),
      );

      expect(tokenizer.charBuffer.flushMainBuffer(), equals('n'));
    });

    test('emits any buffered input when delimiter is passed in after', () {
      tokenizer.generateTokens('n');
      final (buffer, delimiter) = tokenizer.generateTokens('>');

      expect(
        buffer,
        equals((token: 'n', tokenType: DictionaryTokenType.normal)),
      );
      expect(
        delimiter,
        equals((token: '>', tokenType: DictionaryTokenType.mapDelimiter)),
      );
    });
  });

  group('generates tokens', () {
    test('when input is passed in ', () {
      addTokenizerInput('key=value');

      final tokens = tokenizer.tokenize().toList();

      final expectedTokens = <(int, DictionaryToken)>[
        (2, (token: 'key', tokenType: DictionaryTokenType.normal)),
        (3, (token: '=', tokenType: DictionaryTokenType.kvDelimiter)),
        (8, (token: 'value', tokenType: DictionaryTokenType.normal)),
        (-1, tokenizer.getEOCharsToken()),
      ];

      expect(tokens, equals(expectedTokens));
    });

    test(
      'adds error token when no unescaped characters are added in input',
      () {
        addTokenizerInput(r'key\');

        final tokens = tokenizer.tokenize().toList();

        final expectedTokens = <(int, DictionaryToken)>[
          (-1, (token: null, tokenType: DictionaryTokenType.error)),
          (-1, tokenizer.getEOCharsToken()),
        ];

        expect(tokens, equals(expectedTokens));
      },
    );
  });
}
