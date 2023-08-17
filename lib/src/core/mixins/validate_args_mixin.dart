import 'package:magical_version_bump/src/core/extensions/iterable_extension.dart';

/// This mixin validates args normalized to make sure they follow guidelines
mixin ValidatePreppedArgs {
  /// List of action flags. These flags indicate what the command
  ///  is doing. They always come first before any target flag.
  final actions = <String>['bump', 'dump', 'b', 'd'];

  /// List of target flags. These flags indicate what the main
  /// command is targeting in the pubspec.yaml version. Uses semver semantics.
  final targets = <String>[
    'major',
    'minor',
    'patch',
    'build-number',
    'absolute',
  ];

  /// List of any other accepted flags for `Change` and `Generate` commands
  final otherAcceptedFlags = <String>[
    // General for all
    'set-path',

    // For Change command
    'set-prerelease',
    'set-build',
    'keep-pre',
    'keep-build',
    'yaml-version',
    'documentation',
    'issue_tracker',
    'repository',
    'homepage',
    'description',
    'name',

    // For generate command
  ];

  /// Check for any undefined flags
  List<String> checkForUndefinedFlags(List<String> args) {
    return args
        .where(
          (element) =>
              !actions.contains(element) &&
              !targets.contains(element) &&
              !otherAcceptedFlags.contains(element),
        )
        .toList();
  }

  /// Checks if modify flags follow specified sequence i.e. :
  ///
  /// * Starts with an `action` flag
  /// * Never has `bump` or `dump` args used together
  /// * Has at least one target
  String checkModifyFlags(List<String> args) {
    // Check if action flag is first
    final firstArgIsAction = actions.contains(args.first);

    if (!firstArgIsAction) {
      return "${actions.join(', ')} flags should come first";
    }

    // Bump and dump should never be used together
    final hasBumpAndDump = args.containsBumpAndDump();

    if (hasBumpAndDump) {
      return 'bump and dump flags cannot be used together';
    }

    final hasTargetFlag = args.any(
      targets.contains,
    );

    if (!hasTargetFlag) {
      return """Command should have at least one of ${targets.take(4).join(', ')} flags""";
    }

    return '';
  }

  /// Check if any flag occured more than once in command.
  String checkForDuplicates(List<String> args) {
    // Create map with count of each command. Should occur only once
    final map = args.fold(
      <String, int>{},
      (previousValue, element) {
        if (previousValue.containsKey(element)) {
          final count = previousValue[element];

          previousValue.update(element, (value) => count! + 1);

          return previousValue;
        }

        previousValue.addAll({element: 1});

        return previousValue;
      },
    );

    // Check if any has a count of greater than
    final flagDuplicates = map.entries.where((element) => element.value > 1);

    if (flagDuplicates.isNotEmpty) {
      final repeated = StringBuffer();

      // Add count violation to string
      for (final entry in flagDuplicates) {
        repeated.write('${entry.key} -> ${entry.value}\n');
      }

      return 'Found repeated flags:\n$repeated';
    }

    return '';
  }
}
