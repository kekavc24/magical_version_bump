/// This mixin validates args
mixin ValidateArgs {
  /// List of target flags. These flags indicate what the main
  /// command is targeting in the pubspec.yaml version. Uses semver semantics.
  final versionTargets = <String>[
    'major',
    'minor',
    'patch',
    'build-number',
  ];

  /// List of supported yaml nodes, out of the box
  final nodesSupported = <String>[
    'documentation',
    'issue_tracker',
    'repository',
    'homepage',
    'description',
    'name',
  ];

  /// Checks if targets passed to command are valid
  String checkTargets(List<String> targets) {
    if (targets.isEmpty) {
      return 'No targets found';
    }

    final allAreTargets = targets.every(versionTargets.contains);

    if (!allAreTargets) {
      return """Command should have at least one of ${versionTargets.join(', ')} flags""";
    }

    return '';
  }
}
