import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/core/parsers/dictionary_parser/dictionary_parser.dart';

import 'package:magical_version_bump/src/utils/data/version_modifiers.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/exceptions.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:meta/meta.dart';

part 'bump_args_normalizer.dart';
part 'find_args_normalizer.dart';
part 'replace_args_normalizer.dart';
part 'set_args_normalizer.dart';

/// Contains basic code implementations to
///   * Prep args to desired format for each command
///   * Validate arguments
abstract class ArgumentsNormalizer {
  ArgumentsNormalizer({required this.argResults});

  /// Argument results from command
  final ArgResults? argResults;

  /// Basic implementation to check if args are empty or null
  (bool isValid, InvalidReason? reason) validateArgs({
    bool ignoreRestArgs = true,
  }) {
    /// Args must not be empty or null.
    if (argResults == null ||
        argResults!.arguments.isEmpty ||
        (ignoreRestArgs && argResults!.rest.isNotEmpty)) {
      return (
        false,
        const InvalidReason(
          'Missing arguments',
          'Arguments cannot be empty or null',
        ),
      );
    }
    return customValidate();
  }

  @protected
  (bool isValid, InvalidReason? reason) customValidate() => (true, null);

  /// Prep args to desired format
  void prepArgs();
}
