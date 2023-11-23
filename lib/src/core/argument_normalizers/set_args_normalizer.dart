part of 'arg_normalizer.dart';

final class SetArgumentsNormalizer extends ArgumentsNormalizer {
  SetArgumentsNormalizer({required super.argResults});

  /// Prep dictionaries
  @override
  ({
    VersionModifiers modifiers,
    List<Dictionary> dictionaries,
  }) prepArgs() {
    final dictionaries = <Dictionary>[];

    // Get dictionaries to add/overwrite first
    final dictsToAdd = argResults!['dictionary'] as List<String>;

    if (dictsToAdd.isNotEmpty) {
      for (final result in dictsToAdd) {
        final dict = extractDictionary(result, append: false);

        dictionaries.add(dict);
      }
    }

    // Get dictionaries to append to
    final dictsToAppendTo = argResults!['add'] as List<String>;

    if (dictsToAppendTo.isNotEmpty) {
      for (final result in dictsToAppendTo) {
        final dict = extractDictionary(result, append: true);

        dictionaries.add(dict);
      }
    }

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
        violation: 'The root key cannot be empty/null',
      );
    }

    // Must have 2 values, the keys & value(s)
    final keysAndValue = parsedValue.splitAndTrim('=');
    final hasNoBlanks = keysAndValue.every((element) => element.isNotEmpty);

    if (keysAndValue.length != 2 || !hasNoBlanks) {
      throw MagicalException(
        violation: 'Invalid keys and value pair at "$parsedValue"',
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
