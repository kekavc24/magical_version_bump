part of 'dictionary_parser.dart';

/// Used to separate consecutive keys in a map
///
/// Example:
/// ```json
/// { "key": { "anotherKey" : "value" } } // json
/// ```
///
/// The key path is `key|anotherKey`
///
/// ```yaml
/// # yaml
/// key:
///   anotherKey: value
/// ```
const _keyDelimiter = '|';

/// Used to separate map literals.
///
/// Example: `key>anotherKey>value` results in:
///
/// ```json
/// { "key": { "anotherKey" : "value" } } // json
/// ```
const _mapDelimiter = '>';

/// Used to separate list literals.
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
  none(isDelimiter: false),
  normal(isDelimiter: false),
  error(isDelimiter: false),
  keyDelimiter(isDelimiter: true),
  mapDelimiter(isDelimiter: true),
  listDelimiter(isDelimiter: true),
  kvDelimiter(isDelimiter: true),
  escapeDelimiter(isDelimiter: true),
  end(isDelimiter: false);

  const DictionaryTokenType({required this.isDelimiter});

  final bool isDelimiter;
}

typedef DictionaryToken = ({
  DictionaryTokenType tokenType,
  String? token,
});
