part of 'arg_sanitizer.dart';

/// Preps args for change command.
/// Uses default method from parent class to validate.
final class ChangeArgumentSanitizer extends ArgumentSanitizer {
  /// Prep change args
  @override
  ArgsAndValues prepArgs(List<String> args) {
    final argsAndValues = <String, String>{};

    for (final argument in args) {
      final value = argument.split('=');

      argsAndValues.addEntries([MapEntry(value.first, value.last)]);
    }

    return argsAndValues;
  }
}
