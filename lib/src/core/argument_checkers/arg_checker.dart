import 'package:args/args.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';

part 'bump_args_checker.dart';
part 'set_args_checker.dart';

/// Contains basic code implementations to
///   * Prep args to desired format for each command
///   * Validate arguments
base class ArgumentsChecker with NormalizeArgs, ValidateArgs {
  ArgumentsChecker({required this.argResults});

  /// Argument results from command
  final ArgResults? argResults;

  /// Basic implementation to check if args are empty or null
  ({bool isValid, InvalidReason? reason}) validateArgs() {
    // Args must not be empty or null
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

  /// Fetch path information
  ({bool requestPath, String path}) get pathInfo => checkPath(argResults!);

  /// Fetch version modifiers
  ({
    bool preset,
    bool presetOnlyVersion,
    String? version,
    String? prerelease,
    String? build,
    bool keepPre,
    bool keepBuild,
  }) modifiers({required bool checkPreset}) => checkForVersionModifiers(
        argResults!,
        checkPreset: checkPreset,
      );

  /// Prep args to desired format
  void prepArgs() {}
}
