import 'package:args/args.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';

part 'bump_args_sanitizer.dart';
part 'set_args_sanitizer.dart';

/// Contains basic code implementations to
///   * Normalize args
///   * Validate args
///
/// Each command has a specific way to handle this in that :
///   * Modify command - requires specific order for flag declaration
///   * Change command - requires no order
///
/// They, however, share some code.
base class ArgumentSanitizer with NormalizeArgs, ValidateArgs {
  ArgumentSanitizer({required this.argResults});

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
  }) get modifiers => checkForVersionModifiers(argResults!);

  /// Prep args to desired format
  void prepArgs() {}
}
