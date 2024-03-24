part of 'dictionary_parser.dart';

/// Used to separate map literals.
///
/// Example: `key>anotherKey>value` results in:
///
/// ```json
/// { "key": { "anotherKey" : "value" } } // json
/// ```
const _mapDelimiter = '>';

/// Used to separate list literals for both keys and values
///
/// Example: `value,anotherValue` outputs:
///
/// ```json
/// [value,anotherValue]
/// ```
const _listDelimiter = ',';

/// Used to separate key-value literals.
///
/// Example: `key=value` outputs
///
/// ```json
/// { "key": "value"} // json
/// ```
const _kvDelimiter = '=';

/// Used to enclose raw json literals
const _jsonLiteralDelimiter = '`';

/// Used to denotes starting of json map
const _jsonLiteralOpenMap = '{';

/// Used to pair a key with value
const _jsonLiteralKVDelimiter = ':';

/// Used to denotes end of json map
const _jsonLiteralCloseMap = '}';

/// Used to denote start of json list
const _jsonLiteralOpenList = '[';

/// Used to denotes end of json list
const _jsonLiteralCloseList = ']';

/// Used to wrap values constructed in json
const _jsonLiteralQuote = '"';

/// Used to escape all stated delimiters & itself
const _escaperDelimiter = r'\';

enum DictionaryTokenType {
  /// A fancy way to denote nothing. Helps the [DictionaryTokenizer] accumulate
  /// characters before emitting a [DictionaryToken] with token type
  /// [DictionaryTokenType.normal]
  none,

  /// Denotes a full word/token that can act as a key/value
  normal,

  /// Denotes a raw json literal that needs to be decoded
  jsonLiteral,

  /// A fancy way of telling the [DictionaryParser] that the last token was an
  /// escape character. Usually emitted just before [DictionaryTokenType.end]
  error,

  /// Denotes a map pointer to the next key/value. Default value is `>`
  mapDelimiter,

  /// Denotes a delimiter for specifying more than one key/value. Default
  /// value is `,`
  listDelimiter,

  /// Denotes a delimiter separating keys & values. Default value is `=`
  kvDelimiter,

  /// Denotes a delimiter for escaping any delimiter and itself. Default value
  /// is `\`.
  escapeDelimiter,

  /// Denotes a delimiter for a stringified json literal. Default value is the
  /// backtick itself
  jsonLiteralDelimiter,

  /// Denotes the start of a json map. Default value is `{`.
  jsonOpenMap,

  /// Denotes the end of a key and start of a value. Dedault value is `:`.
  jsonKVDelimiter,

  /// Denotes the close/end of a json map. Default is `}`.
  jsonCloseMap,

  /// Denotes the start of a json list. Default is `[`.
  jsonOpenList,

  /// Denotes the end of a json list. Default is `]`.
  jsonCloseList,

  /// Used by [DictionaryTokenizer] indicate no more tokens are available for
  /// parsing to [DictionaryParser]
  end;

  /// Checks type of token using a single character
  static DictionaryTokenType checkTokenType(String char) {
    return switch (char) {
      _mapDelimiter => DictionaryTokenType.mapDelimiter,
      _listDelimiter => DictionaryTokenType.listDelimiter,
      _escaperDelimiter => DictionaryTokenType.escapeDelimiter,
      _kvDelimiter => DictionaryTokenType.kvDelimiter,
      _jsonLiteralDelimiter => DictionaryTokenType.jsonLiteralDelimiter,
      _jsonLiteralOpenMap => DictionaryTokenType.jsonOpenMap,
      _jsonLiteralKVDelimiter => DictionaryTokenType.jsonKVDelimiter,
      _jsonLiteralCloseMap => DictionaryTokenType.jsonCloseMap,
      _jsonLiteralOpenList => DictionaryTokenType.jsonOpenList,
      _jsonLiteralCloseList => DictionaryTokenType.jsonCloseList,
      _ => DictionaryTokenType.normal,
    };
  }
}

typedef DictionaryToken = ({
  DictionaryTokenType tokenType,
  String? token,
});

extension _DictTokenTypeExt on DictionaryTokenType {
  /// An easy way to check if the token type is a delimiter
  bool isDelimiter({bool isBufferingJson = false, bool isEscaped = false}) {
    return switch (this) {
      DictionaryTokenType.none => false,
      DictionaryTokenType.normal => false,
      DictionaryTokenType.jsonLiteral => false,
      DictionaryTokenType.error => false,
      DictionaryTokenType.mapDelimiter => !isEscaped,
      DictionaryTokenType.listDelimiter => !isEscaped,
      DictionaryTokenType.kvDelimiter => !isEscaped,
      DictionaryTokenType.escapeDelimiter => !isEscaped,
      DictionaryTokenType.jsonLiteralDelimiter  => isBufferingJson,
      DictionaryTokenType.jsonOpenMap => isBufferingJson,
      DictionaryTokenType.jsonKVDelimiter => isBufferingJson,
      DictionaryTokenType.jsonCloseMap => isBufferingJson,
      DictionaryTokenType.jsonOpenList => isBufferingJson,
      DictionaryTokenType.jsonCloseList => isBufferingJson,
      DictionaryTokenType.end => true,
    };
  }

  /// Helps [DictionaryTokenizer] to know which tokens to pass on to
  /// [DictionaryParser]
  bool get isYieldable => switch (this) {
        DictionaryTokenType.none => false,
        DictionaryTokenType.normal => true,
        DictionaryTokenType.jsonLiteral => true,
        DictionaryTokenType.error => true,
        DictionaryTokenType.mapDelimiter => true,
        DictionaryTokenType.listDelimiter => true,
        DictionaryTokenType.kvDelimiter => true,
        DictionaryTokenType.escapeDelimiter => false,
        DictionaryTokenType.jsonLiteralDelimiter => false,
        DictionaryTokenType.jsonOpenMap => false,
        DictionaryTokenType.jsonKVDelimiter => false,
        DictionaryTokenType.jsonCloseMap => false,
        DictionaryTokenType.jsonOpenList => false,
        DictionaryTokenType.jsonCloseList => false,
        DictionaryTokenType.end => true
      };

  /// Checks whether [DictionaryTokenizer] should add quotation marks to the
  /// before buffering a character
  bool get shouldTriggerQuoting => switch (this) {
        DictionaryTokenType.jsonOpenList ||
        DictionaryTokenType.jsonCloseList ||
        DictionaryTokenType.jsonOpenMap ||
        DictionaryTokenType.jsonCloseMap ||
        DictionaryTokenType.jsonKVDelimiter ||
        DictionaryTokenType.listDelimiter =>
          true,
        _ => false
      };
}
