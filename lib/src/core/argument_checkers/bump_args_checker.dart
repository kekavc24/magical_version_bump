part of 'arg_checker.dart';

/// Preps and validates args for modify command
final class BumpArgumentsChecker extends ArgumentsChecker {
  BumpArgumentsChecker({required super.argResults});

  /// Validate modify args
  ({bool isValid, InvalidReason? reason}) customValidate() {
    // Check args normally
    final checkArgs = validateArgs();

    if (!checkArgs.isValid) {
      return checkArgs;
    }

    final errInTargets = checkTargets(
      argResults!['targets'] as List<String>,
    );

    return (
      isValid: errInTargets.isEmpty,
      reason: errInTargets.isEmpty
          ? null
          : InvalidReason('Invalid targets', errInTargets),
    );
  }

  /// Prep modify args
  @override
  ({ModifyStrategy strategy, List<String> targets}) prepArgs() {
    // Check strategy
    final strategy = argResults!['strategy'].toString().bumpStrategy;

    // Get targets
    final parsedTargets = argResults!['targets'] as List<String>;

    return (
      strategy: strategy,
      targets: strategy == ModifyStrategy.relative
          ? parsedTargets.getRelative()
          : parsedTargets,
    );
  }
}
