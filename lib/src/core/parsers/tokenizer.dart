part of 'parser.dart';

abstract base class Tokenizer<IntermediateTokenT, TokenT> {
  /// A buffer to accumulate chars for use
  final charBuffer = StackedBuffer();

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

enum QuoteFixMode {
  /// Appends at the beginning and the end of the input
  bothEnds(addAtHead: true, addAtTail: true),

  /// Appends only at the beginning of the input
  preppend(addAtHead: true, addAtTail: false),

  /// Appends only at the end of the input
  append(addAtHead: false, addAtTail: true),

  /// Input remains untouched
  none(addAtHead: false, addAtTail: false);

  const QuoteFixMode({required this.addAtHead, required this.addAtTail});
  final bool addAtHead;
  final bool addAtTail;
}

/// Custom buffer that efficiently buffers characters/strings generated by
/// any [Tokenizer].
base class StackedBuffer {
  final _mainCharBuffer = StringBuffer();
  final _temporaryBuffer = <String>[];

  /// Adds a character/string directly to the main char buffer
  void pushToMainBuffer(String char) => _mainCharBuffer.write(char);

  /// Adds a character/string to a temporary buffer for future preprocessing
  void pushToTempBuffer(String char) => _temporaryBuffer.add(char);

  /// Obtains the last index of temporary buffer with character
  int get lastTempBufferIndex => _temporaryBuffer.length - 1;

  /// Obtains the input accumulated in the temporary buffer
  String get peekTempBuffer => _temporaryBuffer.join();

  /// Peeks a char temporarily buffered character/string by its index. May
  /// return null if index is out of range or if buffer is empty.
  String? peekTempBufferAtIndex(int index) =>
      index >= _temporaryBuffer.length ? null : _temporaryBuffer[index];

  /// Peeks last character/string temporarily buffered.
  String get lastTempBufferedChar => _temporaryBuffer.lastOrNull ?? '';

  /// Adds any input present in the temporary buffer and wraps it with any
  /// character provided.
  void flushTempBuffer({required QuoteFixMode fixMode, String wrapper = ''}) {
    if (_temporaryBuffer.isEmpty) return;
    
    pushToMainBuffer(
      fixMode == QuoteFixMode.none
          ? peekTempBuffer
          : '''${fixMode.addAtHead ? wrapper : ''}$peekTempBuffer${fixMode.addAtTail ? wrapper : ''}''',
    );
    _temporaryBuffer.clear();
  }

  /// Flushes the temporary buffer with [QuoteFixMode.none] and empties the
  /// input currently buffered in the main buffer. Returns null if empty.
  String? flushMainBuffer() {
    if (_temporaryBuffer.isNotEmpty){
      flushTempBuffer(fixMode: QuoteFixMode.none);
    }
    if (_mainCharBuffer.isEmpty) return null;
    final buffer = _mainCharBuffer.toString();
    _mainCharBuffer.clear();
    return buffer;
  }
}
