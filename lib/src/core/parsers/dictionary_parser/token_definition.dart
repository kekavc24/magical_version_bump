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

/// Used to escape all stated delimiters & itself
const _escaperDelimiter = r'\';

enum DictionaryTokenType {
  /// A fancy way to denote nothing. Helps the [DictionaryTokenizer] accumulate 
  /// characters before emitting a [DictionaryToken] with token type 
  /// [DictionaryTokenType.normal]
  none(isDelimiter: false),

  /// Denotes a full word/token that can act as a key/value
  normal(isDelimiter: false),

  /// A fancy way of telling the [DictionaryParser] that the last token was an 
  /// escape character. Usually emitted just before [DictionaryTokenType.end]
  error(isDelimiter: false),

  /// Denotes a map pointer to the next key/value. Default value is `>`
  mapDelimiter(isDelimiter: true),

  /// Denotes a delimiter for specifying more than one key/value. Default 
  /// value is `,`
  listDelimiter(isDelimiter: true),

  /// Denotes a delimiter separating keys & values. Default value is `=`
  kvDelimiter(isDelimiter: true),

  /// Denotes a delimiter for escaping any delimiter and itself. Default value 
  /// is `\`.
  escapeDelimiter(isDelimiter: true),

  /// Used by [DictionaryTokenizer] indicate no more tokens are available for
  /// parsing to [DictionaryParser]
  end(isDelimiter: false);

  const DictionaryTokenType({required this.isDelimiter});

  /// An easy way to check if the token type is a delimiter 
  final bool isDelimiter;
}

typedef DictionaryToken = ({
  DictionaryTokenType tokenType,
  String? token,
});
