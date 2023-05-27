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

    return (
      args: sanitizedArgs.where((arg) => !arg.contains('set-path')).toList(),
      hasPath: sanitizedArgs.contains('set-path'),
      setPath: sanitizedArgs.contains('set-path')
          ? sanitizedArgs.firstWhere((arg) => arg.contains('set-path'))
          : null
    );
  }

  /// Prep normalized args
  ({
    bool absoluteVersioning,
    String action,
    List<String> versionTargets,
    bool requestPath,
  }) prepArgs(List<String> args) {
    final actionFlag = args.first; // Action command

    // Targets
    final targetFlags = args.where((element) => element != actionFlag).toList();

    // Check if path was in list
    final wasInTargetFlags = targetFlags.remove('with-path');

    final absoluteBump = targetFlags.remove('absolute');

    return (
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
