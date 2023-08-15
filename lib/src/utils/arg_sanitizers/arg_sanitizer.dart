import 'package:magical_version_bump/src/core/enums/enums.dart';
import 'package:magical_version_bump/src/core/mixins/command_mixins.dart';
import 'package:magical_version_bump/src/core/typedefs/typedefs.dart';

part 'change_arg_sanitizer.dart';
part 'modify_arg_sanitizer.dart';

/// Contains basic code implementations to
///   * Normalize args
///   * Validate args
///
/// Each command has a specific way to handle this in that :
///   * Modify command - requires specific order for flag declaration
///   * Change command - requires no order
///
/// They, however, share some code.
base class ArgumentSanitizer with NormalizeArgs, ValidatePreppedArgs {
  /// Normalize args
  ({
    List<String> args,
    String? path,
    String? version,
    String? build,
    String? prerelease,
    bool keepPre,
    bool keepBuild,
    bool preset,
    bool presetOnlyVersion,
  }) sanitizeArgs(List<String> args) {
    final normalizedArgs = normalizeArgs(args);

    return checkForSetters(normalizedArgs);
  }

  /// Basic implementation of validate args
  ({bool isValid, InvalidReason? reason}) validateArgs(List<String> args) {
    // Check for undefined flags
    final undefinedFlags = checkForUndefinedFlags(args);

    if (undefinedFlags.isNotEmpty) {
      return (
        isValid: false,
        reason: InvalidReason(
          'Invalid arguments',
          """${undefinedFlags.join(', ')} ${undefinedFlags.length <= 1 ? 'is not a defined flag' : 'are not  defined flags'}""",
        ),
      );
    }

    // Check for duplicated flags
    final repeatedFlags = checkForDuplicates(args);

    if (repeatedFlags.isNotEmpty) {
      return (
        isValid: false,
        reason: InvalidReason('Duplicate flags', repeatedFlags),
      );
    }

    return (isValid: true, reason: null);
  }

  /// Prep args to desired formart
  void prepArgs(List<String> args) {}
}
