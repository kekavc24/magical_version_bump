part of 'dictionary_parser.dart';

typedef IntermediateDictToken = (DictionaryToken, DictionaryToken?);

final class DictionaryTokenizer
    extends Tokenizer<IntermediateDictToken, DictionaryToken> {
  DictionaryTokenizer._(this.input);

  DictionaryTokenizer.addInput(String input) : this._(input);

  DictionaryTokenizer.empty() : this.addInput('');

  String input;

  /// Last token tokenized and (not) emitted
  DictionaryTokenType _previousTokenType = DictionaryTokenType.none;

  /// Indicates whether a json string is being tokenized/cleaned
  bool _isTokenizingJsonLiteral = false;

  /// Indicates last character tokenized in a json string
  String? _lastJsonLiteralChar;

  /// Keeps track of all indices of a json string's quotation marks. Ensures
  /// we correctly clean the json keys/values for Dart's json decoder.
  final _quoteIndices = <int>[];

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
        if (first.tokenType.isYieldable && !_isTokenizingJsonLiteral) {
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

    /// If last token as an escape, indicate to parser. We won't need to
    /// flust buffer for json literals as that is done after the closing
    /// json literal
    if (_previousTokenType == DictionaryTokenType.escapeDelimiter ||
        _isTokenizingJsonLiteral) {
      yield (
        -1, // Expected position for unescaped character
        (
          token: _isTokenizingJsonLiteral ? 'json-literal' : null,
          tokenType: DictionaryTokenType.error,
        ),
      );
    } else {
      final lastEntry = _flushBuffer();
      if (lastEntry != null) yield (lastPosition, lastEntry);
    }

    yield (-1, getEOCharsToken());
  }

  @override
  IntermediateDictToken generateTokens(String char) {
    final tokenType = DictionaryTokenType.checkTokenType(char);

    final isEscaped = _previousTokenType == DictionaryTokenType.escapeDelimiter;
    final isEscaping =
        !isEscaped && tokenType == DictionaryTokenType.escapeDelimiter;

    if ((_isTokenizingJsonLiteral ||
            tokenType == DictionaryTokenType.jsonLiteralDelimiter) &&
        !isEscaping) {
      return _tokenizeJsonLiteral(isEscaped, tokenType, char);
    }

    /// If last token type was being escaped or a normal one, write to buffer.
    /// Then return a token that prevents the generator from yielding a new
    /// token
    if (tokenType == DictionaryTokenType.normal || isEscaped) {
      charBuffer.pushToMainBuffer(char);
      return ((token: null, tokenType: DictionaryTokenType.none), null);
    }

    final defaultToken = (token: char, tokenType: tokenType);

    DictionaryToken? preYield;

    // Attempt to obtain any buffered tokens
    if (_previousTokenType == DictionaryTokenType.none && !isEscaping) {
      preYield = _flushBuffer();
    }
    return preYield != null ? (preYield, defaultToken) : (defaultToken, null);
  }

  /// Tokenizes json literal strings
  IntermediateDictToken _tokenizeJsonLiteral(
    bool isEscaped,
    DictionaryTokenType tokenType,
    String char,
  ) {
    if (tokenType == DictionaryTokenType.jsonLiteralDelimiter && !isEscaped) {
      if (_isTokenizingJsonLiteral) {
        _isTokenizingJsonLiteral = false;
        _lastJsonLiteralChar = null;
        return (
          _flushBuffer(DictionaryTokenType.jsonLiteral) ??
              (token: '', tokenType: DictionaryTokenType.jsonLiteral),
          null,
        );
      }

      _isTokenizingJsonLiteral = true;
      return ((token: null, tokenType: tokenType), null);
    }

    // Ignore all spaces that aren't escaped
    if (char == ' ' && !isEscaped) {
      _lastJsonLiteralChar = char;
      return ((token: null, tokenType: _previousTokenType), null);
    }

    /// Add directly to temp buffer if character is escaped or the
    /// last character was escaped while escaping a character
    if (isEscaped || _lastJsonLiteralChar == r'\') {
      _lastJsonLiteralChar = char;
      charBuffer.pushToTempBuffer(char);
      return ((token: null, tokenType: DictionaryTokenType.none), null);
    }

    if (tokenType.shouldTriggerQuoting) {
      // Flush temporary before next json delimiter token
      charBuffer
        ..flushTempBuffer(
          mode: _optimumQuoteFixMode(),
          wrapper: _jsonLiteralQuote,
        )
        ..pushToMainBuffer(char);
    } else {
      if (char == _jsonLiteralQuote) {
        _quoteIndices.add(charBuffer.lastTempBufferIndex + 1);
      }
      charBuffer.pushToTempBuffer(char);
    }

    _lastJsonLiteralChar = char;
    return ((token: null, tokenType: tokenType), null);
  }

  /// Flushes buffer and emits a dictionary token if not empty
  DictionaryToken? _flushBuffer([DictionaryTokenType? tokenType]) {
    final buffer = charBuffer.flushMainBuffer();
    if (buffer != null) {
      return (
        token: buffer,
        tokenType: tokenType ?? DictionaryTokenType.normal,
      );
    }
    return null;
  }

  /// Obtains the best way to prepend or append
  QuoteFixMode _optimumQuoteFixMode() {
    if (_quoteIndices.isEmpty) return QuoteFixMode.bothEnds;

    // Indices of all quotation marks
    final (min, max) = _quoteIndices.getMinAndMax();
    final maxIndex = charBuffer.lastTempBufferIndex;
    _quoteIndices.clear(); // Remove indices

    // When not:
    return switch (min!) {
      > 0 when max! < maxIndex => QuoteFixMode.bothEnds, // At either start/end
      == 0 when max! < maxIndex => QuoteFixMode.append, // At end
      > 0 when max! == maxIndex => QuoteFixMode.preppend, // At start
      _ => QuoteFixMode.none, // At start and end or if equal
    };
  }
}
