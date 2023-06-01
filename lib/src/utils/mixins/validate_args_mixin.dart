import 'package:mason_logger/mason_logger.dart';

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
    // General for all
    'set-path',

    // For Change command
    'set-prelease',
    'set-build',
    'keep-pre',
    'keep-build',
    'yaml-version',
    'documentation',
    'issue_tracker',
    'repository',
    'homepage',
    'description',
    'name'

    // For generate command
  ];

  /// Check if args normalized correctly
  Future<({InvalidReason? invalidReason, List<String> args})> validateArgs(
    List<String> args, {
    required bool userSetPath,
    required Logger logger,
    bool isModify = false,
  }) async {
    // Args must not be empty
    if (args.isEmpty) {
      return (
        invalidReason: const InvalidReason(
          'Missing arguments',
          'No arguments found',
        ),
        args: <String>[],
      );
    }

    final modifiableArgs = [...args];

    // Check for undefined flags
    final undefinedFlags = _checkForUndefinedFlags(modifiableArgs);

    if (undefinedFlags.isNotEmpty) {
      return (
        invalidReason: InvalidReason(
          'Invalid arguments',
          """${undefinedFlags.join(', ')} ${undefinedFlags.length <= 1 ? 'is not a defined flag' : 'are not  defined flags'}""",
        ),
        args: <String>[],
      );
    }

    // Remove any "with-path" flag if user set path. Warn too
    if (userSetPath) {
      // Warn user
      final hasPathFlag = modifiableArgs.any(
        (element) => element == 'with-path' || element.contains('set-path'),
      );

      if (hasPathFlag) {
        logger.warn('Duplicate flags were found when path was set');

        modifiableArgs
          ..remove('with-path')
          ..retainWhere((element) => !element.contains('set-path'));
      }
    }

    // Check for correct order of flags as specified above on `actions` &
    // `targets` variables
    if (isModify) {
      final standardsError = _checkFlags(modifiableArgs);

      if (standardsError.isNotEmpty) {
        return (
          invalidReason: InvalidReason('Wrong flag sequence', standardsError),
          args: <String>[],
        );
      }
    }

    // Get duplicated flags
    final repeatedFlags = _checkForDuplicates(modifiableArgs);

    if (repeatedFlags.isNotEmpty) {
      return (
        args: <String>[],
        invalidReason: InvalidReason('Duplicate flags', repeatedFlags),
      );
    }

    return (invalidReason: null, args: modifiableArgs);
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
      return "${actions.join(', ')} flags should come first";
    }

    final hasTargetFlag = args.any(
      (element) => element != 'with-path' && targets.contains(element),
    );

    if (!hasTargetFlag) {
      return """Command should have at least one of ${targets.take(4).join(', ')} flags""";
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

      return 'Found repeated flags:\n$repeated';
    }

    return '';
  }
}
