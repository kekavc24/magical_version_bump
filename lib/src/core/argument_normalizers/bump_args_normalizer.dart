part of 'arg_normalizer.dart';

/// Preps and validates args for modify command
final class BumpArgumentsNormalizer extends ArgumentsNormalizer {
  BumpArgumentsNormalizer({required super.argResults});

  late List<String> _targets;

  @override
  ({bool isValid, InvalidReason? reason}) customValidate() {
    // Get targets
    _targets = argResults!.targets;

    if (_targets.isEmpty) {
      return (
        isValid: false,
        reason: const InvalidReason(
          'Invalid targets',
          '''You need to pass in a target i.e. major, minor, patch or build-number''',
        ),
      );
    }
    return super.customValidate();
  }

  /// Prep modify args
  @override
  ({VersionModifiers modifiers, List<String> targets}) prepArgs() {
    // Get version modifiers
    final modifiers = VersionModifiers.fromBumpArgResults(argResults!);

    return (
      modifiers: modifiers,
      targets: modifiers.strategy == ModifyStrategy.relative
          ? _targets.getRelative()
          : _targets,
    );
  }
}
