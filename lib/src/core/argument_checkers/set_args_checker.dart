part of 'arg_checker.dart';

final class SetArgumentsChecker extends ArgumentsChecker {
  SetArgumentsChecker({required super.argResults});

  /// Prep arguments and values as Map<String, String>
  @override
  List<Dictionary> prepArgs() {
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

    return dictionaries;
  }

  /// Validate and return prepped args
  ({
    bool isValid,
    InvalidReason? reason,
    List<Dictionary>? dictionaries,
  }) customValidate({required bool didSetVersion}) {
    // Check if arguments results are empty
    final checkedArgs = validateArgs();

    if (!checkedArgs.isValid && !didSetVersion) {
      return (
        isValid: checkedArgs.isValid,
        reason: checkedArgs.reason,
        dictionaries: null,
      );
    }

    // Prep args
    final preppedArgs = prepArgs();

    return (
      isValid: preppedArgs.isNotEmpty || didSetVersion,
      reason: preppedArgs.isNotEmpty || didSetVersion
          ? null
          : const InvalidReason('Missing arguments', 'No arguments found'),
      dictionaries: preppedArgs.isNotEmpty ? preppedArgs : null,
    );
  }
}
