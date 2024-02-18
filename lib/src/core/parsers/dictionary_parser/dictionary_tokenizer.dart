part of 'dictionary_parser.dart';

final class DictionaryTokenizer
    extends Tokenizer<(DictionaryToken, DictionaryToken?), DictionaryToken> {
  DictionaryTokenizer._(this.input);

  DictionaryTokenizer.addInput(String input) : this._(input);

  DictionaryTokenizer.empty() : this.addInput('');

  String input;

  DictionaryTokenType _previousTokenType = DictionaryTokenType.none;

  @override
  DictionaryToken getEOCharsToken() =>
      (tokenType: DictionaryTokenType.end, token: null);

  @override
  Iterable<(int currentPosition, DictionaryToken token)> tokenize() sync* {
    var lastPosition = 0;

    for (final (index, char) in generateCharacters(input)) {
      lastPosition = index;
      final (first, second) = generateTokens(char);

      if (second == null) {
        // Emit token if any are available
        if (first.tokenType != DictionaryTokenType.none &&
            first.tokenType != DictionaryTokenType.escapeDelimiter) {
          yield (index, first);
        }
        _previousTokenType = first.tokenType;
        continue;
      }

      /// We only emit two to reconcile word built in buffer before
      /// encountering a delimiter that is not an escape character.
      ///
      /// It's index precedes the index of a non-escaped delimiter
      yield (index - 1, first);
      yield (index, second);
      _previousTokenType = second.tokenType;
    }

    // If last token as an escape, indicate to parser
    if (_previousTokenType == DictionaryTokenType.escapeDelimiter) {
      yield (
        -1, // Expected position for unescaped character
        (token: null, tokenType: DictionaryTokenType.error),
      );
    } else {
      final lastEntry = _flushBuffer();
      if (lastEntry != null) yield (lastPosition, lastEntry);
    }

    yield (-1, getEOCharsToken());
  }

  @override
  (DictionaryToken, DictionaryToken?) generateTokens(String char) {
    final tokenType = _checkTokenType(char);

    /// If last token type was being escaped or a normal one, write to buffer.
    /// Then return a token that prevents the generator from yielding a new
    /// token
    if (tokenType == DictionaryTokenType.normal ||
        _previousTokenType == DictionaryTokenType.escapeDelimiter) {
      addToBuffer(char);
      return ((token: null, tokenType: DictionaryTokenType.none), null);
    }

    final defaultToken = (token: char, tokenType: tokenType);
    DictionaryToken? preYield;

    // Attempt to obtain any buffered tokens
    if (_previousTokenType == DictionaryTokenType.none &&
        tokenType != DictionaryTokenType.escapeDelimiter) {
      preYield = _flushBuffer();
    }
    return preYield != null ? (preYield, defaultToken) : (defaultToken, null);
  }

  DictionaryTokenType _checkTokenType(String char) {
    return switch (char) {
      _mapDelimiter => DictionaryTokenType.mapDelimiter,
      _listDelimiter => DictionaryTokenType.listDelimiter,
      _escaperDelimiter => DictionaryTokenType.escapeDelimiter,
      _kvDelimiter => DictionaryTokenType.kvDelimiter,
      _ => DictionaryTokenType.normal,
    };
  }

  DictionaryToken? _flushBuffer() {
    var buffer = '';
    if ((buffer = getBuffer(reset: false)).isNotEmpty) {
      resetBuffer();
      return (token: buffer, tokenType: DictionaryTokenType.normal);
    }
    return null;
  }
}
