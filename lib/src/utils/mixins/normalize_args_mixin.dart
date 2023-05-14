import 'package:magical_version_bump/src/utils/models/magical_data_model.dart';

typedef ArgsAndValues = Map<String, String>;

/// This mixin normalizes arguments passed passed in by user
mixin NormalizeArgs {
  /// Normalize arguments. Remove '-' or '--' present
  List<String> normalizeArgs(List<String> args) => args.map((e) {
        var mod = e.replaceFirst(RegExp('--'), '');

        if (mod[0] == '-') mod = mod.replaceFirst(RegExp('-'), '');

        return mod;
      }).toList();

  /// Prep normalized args and return data model
  PrepCommandData prepArgs(List<String> args) {
    final actionFlag = args.first; // Action command

    // Targets
    final targetFlags = args.where((element) => element != actionFlag).toList();

    // Check if path was in list
    final wasInTargetFlags = targetFlags.remove('with-path');

    final absoluteBump = targetFlags.remove('absolute');

    return PrepCommandData(
      absoluteVersioning: absoluteBump,
      action: actionFlag,
      versionTargets: targetFlags,
      requestPath: wasInTargetFlags,
    );
  }

  /// Prep normalized args for `Change` and `Generate`(may change) commands.
  ArgsAndValues getArgAndValues(List<String> args) {
    final argsAndValues = <String, String>{};

    for (final argument in args) {
      final value = argument.split('=');

      argsAndValues.addEntries([MapEntry(value.first, value.last)]);
    }

    return argsAndValues;
  }
}
