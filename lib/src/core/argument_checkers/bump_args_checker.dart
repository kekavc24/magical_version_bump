part of 'arg_checker.dart';

/// Preps and validates args for modify command
final class BumpArgumentsChecker extends ArgumentsChecker {
  BumpArgumentsChecker({required super.argResults});

  static const error =
      '''You need to pass in a target i.e. major, minor, patch or build-number''';

  @override
  ({bool isValid, InvalidReason? reason}) validateArgs({
    bool ignoreRestArgs = true,
  }) {
    // Check args normally
    final checkArgs = super.validateArgs();

    if (!checkArgs.isValid) {
      return checkArgs;
    }

    return (
      isValid: argResults!.targets.isNotEmpty,
      reason: argResults!.targets.isNotEmpty
          ? null
          : const InvalidReason('Invalid targets', error)
    );
  }

  /// Prep modify args
  @override
  ({VersionModifiers modifiers, List<String> targets}) prepArgs() {
    final parsedTargets = argResults!.targets;

    final modifiers = VersionModifiers.fromBumpArgResults(argResults!);

    return (
      modifiers: modifiers,
      targets: modifiers.strategy == ModifyStrategy.relative
          ? parsedTargets.getRelative()
          : parsedTargets,
    );
  }
}
