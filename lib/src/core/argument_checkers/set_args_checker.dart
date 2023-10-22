part of 'arg_checker.dart';

final class SetArgumentsChecker extends ArgumentsChecker {
  SetArgumentsChecker({required super.argResults});

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
    final values = keysAndValue.last.splitAndTrim(',').retainNonEmpty();

    final isMappy = values.first.contains('->');

    /// If more than one value is passed in, we have to check all follow
    /// the same format.
    ///
    /// The first value determines the format the rest should follow!
    if (values.length > 1) {
      final allFollowFormat = values.every(
        (element) => isMappy ? element.contains('->') : !element.contains('->'),
      );

      if (!allFollowFormat) {
        throw MagicalException(
          violation: 'Mixed format at $parsedValue',
        );
      }
    }

    if (isMappy) {
      final valueMap = values.fold(
        <String, String>{},
        (previousValue, element) {
          final mappedValues = element.splitAndTrim('->');
          previousValue.update(
            mappedValues.first,
            (value) => mappedValues.last.isEmpty ? 'null' : mappedValues.last,
            ifAbsent: () =>
                mappedValues.last.isEmpty ? 'null' : mappedValues.last,
          );
          return previousValue;
        },
      );

      return (rootKeys: keys.toList(), append: append, data: valueMap);
    }

    return (
      rootKeys: keys.toList(),
      append: append,
      data: values.length == 1 ? values.first : values.toList(),
    );
  }
}
