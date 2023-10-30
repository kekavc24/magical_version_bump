import 'package:args/args.dart';
import 'package:magical_version_bump/src/utils/data/version_modifiers.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';

part 'bump_args_checker.dart';
part 'set_args_checker.dart';

/// Contains basic code implementations to
///   * Prep args to desired format for each command
///   * Validate arguments
abstract class ArgumentsChecker {
  ArgumentsChecker({required this.argResults});

  /// Argument results from command
  final ArgResults? argResults;

  /// Basic implementation to check if args are empty or null
  ({bool isValid, InvalidReason? reason}) validateArgs() {
    /// Args must not be empty or null. 
    if (argResults == null || argResults!.arguments.isEmpty) {
      return (
        isValid: false,
        reason: const InvalidReason(
          'Missing arguments',
          'Arguments cannot be empty or null',
        ),
      );
    }

    return (isValid: true, reason: null);
  }

  /// Prep args to desired format
  void prepArgs();
}
