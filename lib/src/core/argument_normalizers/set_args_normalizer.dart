part of 'arg_normalizer.dart';

final class SetArgumentsNormalizer extends ArgumentsNormalizer {
  SetArgumentsNormalizer({required super.argResults});

  /// Prep dictionaries
  @override
  ({VersionModifiers modifiers, List<Dictionary> dictionaries}) prepArgs() {
    final dictionaries = <Dictionary>[
      ...argResults!
          .parsedValues('dictionary')
          .map((result) => extractDictionary(result, append: false)),
      ...argResults!
          .parsedValues('add')
          .map((result) => extractDictionary(result, append: true)),
    ];

    return (
      modifiers: VersionModifiers.fromArgResults(argResults!),
      dictionaries: dictionaries,
    );
  }

  /// Extract dictionaries/lists
  Dictionary extractDictionary(String parsedValue, {required bool append}) {
    ///
    /// Format is "key=value,value" or "key=value:value"
    ///
    /// Should never be empty
    if (parsedValue.isEmpty) {
      throw MagicalException(
        message: 'The root key cannot be empty/null',
      );
    }

    // Must have 2 values, the keys & value(s)
    final keysAndValue = parsedValue.splitAndTrim('=').retainNonEmpty();

    if (keysAndValue.length != 2) {
      throw MagicalException(
        message: 'Invalid keys and value pair at "$parsedValue"',
      );
    }

    /// Format for specifying more than 1 key is using "|" as a separator
    ///
    /// i.e. `rootKey`|`nextKey`|`otherKey`
    final keys = keysAndValue.first.splitAndTrim('|').retainNonEmpty();

    /// Format for specifying more than 1 value is ","
    ///
    /// i.e `value`,`nextValue`,`otherValue`
    ///
    /// Remove any empty values in list.
    ///
    /// Dynamically extract any maps present.
    final values = keysAndValue.last
        .splitAndTrim(',')
        .retainNonEmpty()
        .splitBasedOnMatch();

    return (
      rootKeys: keys.toList(),
      updateMode: append ? UpdateMode.append : UpdateMode.overwrite,
      data: values is List && values.length == 1 ? values.first : values,
    );
  }
}
