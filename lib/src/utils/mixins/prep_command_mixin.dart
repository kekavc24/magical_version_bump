import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/models/magical_data_model.dart';
import 'package:mason_logger/mason_logger.dart';

/// This mixin preps the command by checking args passed in command line
mixin PrepCommand {
  /// List of action flags. These flags indicate what the command
  ///  is doing. They always come first before any target flag.
  final _actions = <String>['bump', 'dump', 'b', 'd'];

  /// List of target flags. These flags indicate what the main
  /// command is targeting in the pubspec.yaml version. Uses semver semantics.
  final _targets = <String>[
    'major',
    'minor',
    'patch',
    'build-number',
    'with-path'
  ];

  /// Base string used to append errors
  var _violation = 'Error!';

  /// Get arguments , modify and remove flags i.e "--". Map returned
  /// will include :
  ///   1. String -> action , List<String> -> targets
  ///   2. requestPath -> true/false. Indicates whether to check for file at the
  ///      directory or request path
  Future<PrepCommandData> readArgs({
    required List<String> args,
    required Logger logger,
  }) async {
    final readProgress = logger.progress('Checking arguments');

    // Remove "--".
    final deFlaggedArgs = args.map((e) {
      var mod = e.replaceFirst(RegExp('--'), '');

      if (mod[0] == '-') mod = mod.replaceFirst(RegExp('-'), '');

      return mod;
    });

    // List must not be empty
    if (deFlaggedArgs.isEmpty) {
      readProgress.fail('Missing arguments');
      throw MagicalException(violation: 'No arguments found');
    }

    // Check for undefined flags
    final undefinedFlags = _checkForUndefinedFlags(deFlaggedArgs.toList());

    // Throw undefined flags error
    if (undefinedFlags.isNotEmpty) {
      readProgress.fail('Invalid arguments');
      throw MagicalException(
        violation:
            """${undefinedFlags.join(', ')} ${undefinedFlags.isEmpty ? 'is not a defined flag' : 'are not  defined flags'}""",
      );
    }

    final flagHasError = _checkFlags(deFlaggedArgs.toList());

    // Throw error for flags which don't meet standards
    if (flagHasError.isNotEmpty) {
      readProgress.fail('Invalid arguments');
      throw MagicalException(violation: flagHasError);
    }

    // Get repeated flags
    final repeatedFlags = _checkForDuplicates(deFlaggedArgs.toList());

    // Throw error for repeated flags
    if (repeatedFlags.isNotEmpty) {
      readProgress.fail('Duplicate flags');
      throw MagicalException(violation: repeatedFlags);
    }

    final actionFlag = deFlaggedArgs.first; // Action command

    // Targets
    final targetFlags =
        deFlaggedArgs.where((element) => element != actionFlag).toList();

    // Check if path was in list
    final wasInTargetFlags = targetFlags.remove('with-path');

    readProgress.complete('Checked arguments');

    return PrepCommandData(
      action: actionFlag,
      versionTargets: targetFlags,
      requestPath: wasInTargetFlags,
    );
  }

  /// Check for any undefined flags
  List<String> _checkForUndefinedFlags(List<String> args) => args
      .where(
        (element) => !_actions.contains(element) && !_targets.contains(element),
      )
      .toList();

  /// Verify that first flag is an action flag and contains at least one target
  /// flag
  String _checkFlags(List<String> args) {
    // Check if action flag is first
    final firstArgIsAction = _actions.contains(args.first);

    if (!firstArgIsAction) {
      return _violation += " ${_actions.join(', ')} flags should come first";
    }

    final hasTargetFlag = args.any(
      (element) => element != 'with-path' && _targets.contains(element),
    );

    if (!hasTargetFlag) {
      return _violation +=
          """Command should have at least one of ${_targets.take(4).join(', ')} flags""";
    }

    return '';
  }

  /// Check if action/targets flags occured more than once in command. Return
  /// a string indicating which action flags raised the violation. i.e
  ///   1. bump > 1 || dump > 1 - any occurs more than once
  ///   2. bump && dump - both in command
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

      return _violation += ' Found repeated flags:\n$repeated';
    }

    return '';
  }
}
