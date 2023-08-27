import 'package:magical_version_bump/src/core/arg_sanitizers/arg_sanitizer.dart';

/// This mixin validates args normalized to make sure they follow guidelines
base mixin ValidateArgs on ArgumentSanitizer {
  /// List of target flags. These flags indicate what the main
  /// command is targeting in the pubspec.yaml version. Uses semver semantics.
  final targets = <String>[
    'major',
    'minor',
    'patch',
    'build-number',
  ];

  /// Checks if targets passed to command are valid
  String checkTargets(List<String> targets) {
    final hasTargetFlag = targets.any(
      targets.contains,
    );

    if (!hasTargetFlag) {
      return """Command should have at least one of ${targets.join(', ')} flags""";
    }

    return '';
  }
}
