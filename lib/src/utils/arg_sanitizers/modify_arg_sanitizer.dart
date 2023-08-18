part of 'arg_sanitizer.dart';

/// Preps and validates args for modify command
final class ModifyArgumentSanitizer extends ArgumentSanitizer {
  /// Prep modify args
  @override
  ({
    ModifyStrategy strategy,
    String action,
    List<String> versionTargets,
    bool requestPath,
  }) prepArgs(List<String> args) {
    final actionFlag = args.first; // Action command

    // Targets
    final targetFlags = args.where((element) => element != actionFlag).toList();

    // Check if path was in list
    final wasInTargetFlags = targetFlags.remove('with-path');

    final isAbsolute = targetFlags.remove('absolute');

    return (
      strategy: isAbsolute ? ModifyStrategy.absolute : ModifyStrategy.relative,
      action: actionFlag,
      versionTargets: targetFlags,
      requestPath: wasInTargetFlags,
    );
  }

  /// Validate modify args
  ({bool isValid, InvalidReason? reason}) customValidate(
    List<String> args,
  ) {
    // Args are never empty.
    if (args.isEmpty) {
      return (
        isValid: false,
        reason: const InvalidReason(
          'Missing arguments',
          'Additional arguments for this command are missing',
        ),
      );
    }

    // Check if flag sequence is correct
    final sequenceError = checkModifyFlags(args);

    if (sequenceError.isNotEmpty) {
      return (
        isValid: false,
        reason: InvalidReason('Wrong flag sequence', sequenceError),
      );
    }

    return validateArgs(args); // Default validation
  }
}
