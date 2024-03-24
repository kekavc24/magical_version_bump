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
  bool _isJson = false;

  /// Indicates whether input is be added as is
  bool _addAsIs = false;

  /// Indicates last character tokenized in a json string
  String? _lastJsonChar;

  /// Keeps track of all indices of a json string's quotation marks. Ensures
  /// we correctly clean the json keys/values for Dart's json decoder.
  final _quoteIndices = <int>[];

  bool _addAsJson(DictionaryTokenType tokenType) =>
      _isJson || tokenType == DictionaryTokenType.jsonDelimiter;

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
        if (first.tokenType.isYieldable && !_isJson) {
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

    /// If last token was an escape, indicate to parser. We won't need to
    /// flust buffer for json literals as that is done after the closing
    /// json literal
    if (_previousTokenType == DictionaryTokenType.escapeDelimiter || _isJson) {
      yield (
        -1, // Expected position for unescaped character
        (
          token: _isJson ? 'json-literal' : null,
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
    final wasEscaped =
        _previousTokenType == DictionaryTokenType.escapeDelimiter;

    final tokenType = DictionaryTokenType.checkTokenType(
      char,
      wasEscaped: wasEscaped,
    );

    final isEscaping =
        !wasEscaped && tokenType == DictionaryTokenType.escapeDelimiter;

    if (_addAsJson(tokenType) && !isEscaping) {
      return _tokenizeJsonLiteral(wasEscaped, tokenType, char);
    }

    // Delimiters clear the buffered characters by default
    if (tokenType.isDelimiter()) {
      final defaultToken = (token: char, tokenType: tokenType);

      DictionaryToken? preYield;

      // Attempt to obtain any buffered tokens
      if (_previousTokenType == DictionaryTokenType.none && !isEscaping) {
        preYield = _flushBuffer();
      }
      return preYield != null ? (preYield, defaultToken) : (defaultToken, null);
    }

    charBuffer.pushToMainBuffer(char);
    return ((token: null, tokenType: DictionaryTokenType.none), null);
  }

  /// Tokenizes json literal strings
  IntermediateDictToken _tokenizeJsonLiteral(
    bool isEscaped,
    DictionaryTokenType tokenType,
    String char,
  ) {
    if (tokenType == DictionaryTokenType.jsonDelimiter && !isEscaped) {
      if (_isJson) {
        _isJson = false;
        _lastJsonChar = null;
        return (
          _flushBuffer(DictionaryTokenType.jsonLiteral) ??
              (token: '', tokenType: DictionaryTokenType.jsonLiteral),
          null,
        );
      }

      _isJson = true;
      return ((token: null, tokenType: tokenType), null);
    }

    /// If bang is provided after backtick/ json delimiter
    if (char == '!' &&
        _previousTokenType == DictionaryTokenType.jsonDelimiter) {
      _addAsIs = true;
      return ((token: null, tokenType: _previousTokenType), null);
    }

    // Ignore all spaces that aren't escaped
    if (char == ' ' && !isEscaped) {
      _lastJsonChar = char;
      return ((token: null, tokenType: _previousTokenType), null);
    }

    if (_addAsIs) {
      charBuffer.pushToMainBuffer(char);
    } else {
      ///
      /// Add directly to temp buffer if character is escaped or the
      /// last character was escaped while escaping a character
      if (isEscaped || _lastJsonChar == r'\') {
        _lastJsonChar = char;
        charBuffer.pushToTempBuffer(char);
        return ((token: null, tokenType: DictionaryTokenType.none), null);
      }

      if (tokenType.shouldTriggerQuoting) {
        // Flush temporary before next json delimiter token
        charBuffer
          ..flushTempBuffer(
            fixMode: _optimumQuoteFixMode(),
            wrapper: _jsonQuote,
          )
          ..pushToMainBuffer(char);
      } else {
        if (char == _jsonQuote) {
          _quoteIndices.add(charBuffer.lastTempBufferIndex + 1);
        }
        charBuffer.pushToTempBuffer(char);
      }
    }

    _lastJsonChar = char;
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
    _quoteIndices.clear();

    // When not:
    return switch (min!) {
      > 0 when max! < maxIndex => QuoteFixMode.bothEnds,
      == 0 when max! < maxIndex => QuoteFixMode.append,
      > 0 when max! == maxIndex => QuoteFixMode.preppend,
      _ => QuoteFixMode.none,
    };
  }
}
