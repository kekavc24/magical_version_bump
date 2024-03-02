part of 'dictionary_parser.dart';

typedef IntermediateDictToken = (DictionaryToken, DictionaryToken?);

final class DictionaryTokenizer
    extends Tokenizer<IntermediateDictToken, DictionaryToken> {
  DictionaryTokenizer._(this.input);

  DictionaryTokenizer.addInput(String input) : this._(input);

  DictionaryTokenizer.empty() : this.addInput('');

  String input;

  DictionaryTokenType _previousTokenType = DictionaryTokenType.none;

  bool _isTokenizingJsonLiteral = false;
  String? _lastJsonLiteralChar;
  bool _lastJsonLiteralWasEscaped = false;

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
      yield (index, second); // TODO: Yield only if second is not tokenType.none
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
      addToBuffer(char);
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

  IntermediateDictToken _tokenizeJsonLiteral(
    bool isEscaped,
    DictionaryTokenType tokenType,
    String char,
  ) {
    // // TODO flush buffer only if last token was a list delimiter
    // DictionaryToken? bufferedToken;

    // if (!_isTokenizingJsonLiteral &&
    //     _previousTokenType == DictionaryTokenType.listDelimiter) {
    //   bufferedToken = _flushBuffer();
    // }

    if (tokenType == DictionaryTokenType.jsonLiteralDelimiter && !isEscaped) {
      if (_isTokenizingJsonLiteral) {
        _isTokenizingJsonLiteral = false;
        return (_flushBuffer(DictionaryTokenType.jsonLiteral)!, null);
      }

      _isTokenizingJsonLiteral = true;
      return ((token: null, tokenType: tokenType), null);
    }

    // Ignore all spaces that aren't escaped
    if (char == ' ' && !isEscaped) {
      _lastJsonLiteralChar = char;
      return ((token: null, tokenType: _previousTokenType), null);
    }

    // TODO: Checklist for implementation
    /// 1. Add json quotes before first letter which is after :
    ///     * a jsonOpenList, jsonOpenMap
    ///     * jsonLiteralDelimiter
    ///     * listDelimiter if next is not any of stated above
    /// 2. Add json quotes after last letter/char which is before:
    ///     * a jsonCloseList, jsonCloseMap
    ///     * a json literal
    ///
    /// Heads up,
    /// * All json literals can be escaped
    /// * Space before and after any json delimiter added smoothly
    /// * Return tokenType.none if nothing was buffered previously or
    ///   if json literal is being buffered
    if (isEscaped) {
      _lastJsonLiteralWasEscaped = true;
      _lastJsonLiteralChar = char;
      addToBuffer(char);
      return ((token: null, tokenType: DictionaryTokenType.none), null);
    }

    final isQuotable = _lastJsonLiteralChar != null &&
        _lastJsonLiteralChar != _jsonLiteralQuote &&
        char != _jsonLiteralQuote &&
        !_lastJsonLiteralWasEscaped;

    // Add closing quote before or after
    if (isQuotable &&
        (tokenType.shouldTriggerQuoting ||
            _previousTokenType.shouldTriggerQuoting)) {
      addToBuffer(_jsonLiteralQuote);
    }
    addToBuffer(char);

    if (_lastJsonLiteralWasEscaped) _lastJsonLiteralWasEscaped = false;
    _lastJsonLiteralChar = char;
    return ((token: null, tokenType: tokenType), null);
  }

  DictionaryToken? _flushBuffer([DictionaryTokenType? tokenType]) {
    var buffer = '';
    if ((buffer = getBuffer(reset: false)).isNotEmpty) {
      resetBuffer();
      return (
        token: buffer,
        tokenType: tokenType ?? DictionaryTokenType.normal,
      );
    }
    return null;
  }
}
