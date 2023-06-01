import 'package:magical_version_bump/src/utils/enums/enums.dart';

typedef ArgsAndValues = Map<String, String>;

/// This mixin normalizes arguments passed passed in by user
mixin NormalizeArgs {
  /// Normalize arguments. Remove '-' or '--' present.
  ///
  /// Also obtains the set path
  ({List<String> args, bool hasPath, String? setPath}) normalizeArgs(
    List<String> args,
  ) {
    final sanitizedArgs = args.map((e) {
      var mod = e.replaceFirst(RegExp('--'), '');

      if (mod[0] == '-') mod = mod.replaceFirst(RegExp('-'), '');

      return mod;
    }).toList();

    final hasPath = sanitizedArgs.any((arg) => arg.contains('set-path'));

    return (
      args: hasPath
          ? sanitizedArgs.where((arg) => !arg.contains('set-path')).toList()
          : sanitizedArgs,
      hasPath: hasPath,
      setPath: hasPath
          ? sanitizedArgs
              .firstWhere((arg) => arg.contains('set-path'))
              .split('=')
              .last
          : null
    );
  }

  /// Prep normalized args
  ({
    ModifyStrategy strategy,
    String action,
    List<String> versionTargets,
    bool requestPath,
  }) prepArgs(List<String> args) {
    final actionFlag = args.first; // Action command

    // Targets
    final targetFlags = args.where((element) => element != actionFlag).toList();

    // Check if path was in list
    final wasInTargetFlags = targetFlags.remove('with-path');

    final isAbsolute = targetFlags.remove('absolute');

    return (
      strategy: isAbsolute ? ModifyStrategy.absolute : ModifyStrategy.relative,
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
