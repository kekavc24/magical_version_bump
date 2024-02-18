part of 'parser.dart';

abstract base class Tokenizer<IntermediateTokenT, TokenT> {
  /// A buffer to accumulate chars for use
  final _charBuffer = StringBuffer();

  /// Add a character to buffer
  void addToBuffer(String char) => _charBuffer.write(char);

  /// Obtains the characters accumulated so far in the buffer
  String getBuffer({bool reset = true}) {
    final buffer = _charBuffer.toString();
    if (reset) resetBuffer();
    return buffer;
  }

  /// Clears the internal buffer used by this tokenizer
  void resetBuffer() => _charBuffer.clear();

  /// Returns a custom token indicating no more tokens are available for
  /// consumption
  TokenT getEOCharsToken();

  /// Synchronously generates a stream of token type [TokenT] to be consumed
  /// by a [Parser]
  Iterable<(int currentPosition, TokenT token)> tokenize();

  /// Generates a token from a single character provided to it.
  ///
  /// Override this and use [tokenize] when in needs of tokens .
  IntermediateTokenT generateTokens(String char);
}

/// Generate a synchronous stream of characters from string
Iterable<(int index, String char)> generateCharacters(
  String input, {
  String splitPattern = '',
}) sync* {
  for (final char in input.split(splitPattern).indexed) {
    yield char;
  }
}
