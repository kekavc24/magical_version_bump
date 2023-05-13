typedef InvalidReason = MapEntry<String, String>;

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
    'with-path',
    'absolute'
  ];

  /// List of any other accepted flags for `Change` and `Generate` commands
  final otherAcceptedFlags = <String>[
    // For Change command
    'yaml-version',
    'documentation',
    'issue_tracker',
    'repository',
    'homepage',
    'description',
    'name'

    // For generate command
  ];

  /// Base string used to append errors
  var _baseError = 'Error!';

  /// Check if args normalized correctly
  Future<InvalidReason?> validateArgs(
    List<String> args, {
    required bool isModify,
  }) async {
    // Args must not be empty
    if (args.isEmpty) {
      return const InvalidReason(
        'Missing arguments',
        'No arguments found',
      );
    }

    // Check for undefined flags
    final undefinedFlags = _checkForUndefinedFlags(args);

    if (undefinedFlags.isNotEmpty) {
      return InvalidReason(
        'Invalid arguments',
        """${undefinedFlags.join(', ')} ${undefinedFlags.length <= 1 ? 'is not a defined flag' : 'are not  defined flags'}""",
      );
    }

    // Check for correct order of flags as specified above on `actions` &
    // `targets` variables
    if (isModify) {
      final standardsError = _checkFlags(args);

      if (standardsError.isNotEmpty) {
        return InvalidReason('Wrong flag sequence', standardsError);
      }
    }

    // Get duplicated flags
    final repeatedFlags = _checkForDuplicates(args);

    if (repeatedFlags.isNotEmpty) {
      return InvalidReason('Duplicate flags', repeatedFlags);
    }

    return null;
  }

  /// Check for any undefined flags
  List<String> _checkForUndefinedFlags(List<String> args) => args
      .where(
        (element) =>
            !actions.contains(element) &&
            !targets.contains(element) &&
            !otherAcceptedFlags.contains(element),
      )
      .toList();

  /// Verify that first flag is an action flag and contains at least one target
  /// flag
  String _checkFlags(List<String> args) {
    // Check if action flag is first
    final firstArgIsAction = actions.contains(args.first);

    if (!firstArgIsAction) {
      return _baseError += " ${actions.join(', ')} flags should come first";
    }

    final hasTargetFlag = args.any(
      (element) => element != 'with-path' && targets.contains(element),
    );

    if (!hasTargetFlag) {
      return _baseError +=
          """ Command should have at least one of ${targets.take(4).join(', ')} flags""";
    }

    return '';
  }

  /// Check if action/targets flags occured more than once in command. Return
  /// a string indicating which action flags raised the violation where:
  ///   1. bump > 1 || dump > 1 - any occurs more than once
  ///   2. bump && dump - are both used in the same command
  ///   3. any target flag > 1
  String _checkForDuplicates(List<String> args) {
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

      return _baseError += ' Found repeated flags:\n$repeated';
    }

    return '';
  }
}
