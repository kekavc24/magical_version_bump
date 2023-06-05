import 'package:magical_version_bump/src/utils/enums/enums.dart';

typedef ArgsAndValues = Map<String, String>;

/// This mixin normalizes arguments passed passed in by user
mixin NormalizeArgs {
  /// Flags that match these must be removed first
  final setters = <String>[
    'set-path',
    'set-build',
    'set-prerelease',
    'set-version',
    'keep-pre',
    'keep-build',
    'preset'
  ];

  /// Normalize arguments. Remove '-' or '--' present.
  ///
  /// Also obtains the set path
  List<String> normalizeArgs(List<String> args) {
    final sanitizedArgs = args.map((e) {
      var mod = e.replaceFirst(RegExp('--'), '');

      if (mod[0] == '-') mod = mod.replaceFirst(RegExp('-'), '');

      return mod;
    }).toList();

    return sanitizedArgs;
  }

  /// Check whether user set/used these flags
  /// 1. set-path
  /// 2. set-build
  /// 3. set-prerelease
  /// 4. set-version
  /// 5. keep-pre
  /// 6. keep-build
  ({
    List<String> args,
    String? path,
    String? version,
    String? build,
    String? prerelease,
    bool keepPre,
    bool keepBuild,
    bool preset,
    bool presetOnlyVersion,
  }) checkForSetters(List<String> args) {
    final modifiableArgs = [...args]; // Modifiable list

    final modifiableMap = <String, dynamic>{
      'set-path': null,
      'set-build': null,
      'set-prerelease': null,
      'set-version': null,
      'keep-pre': false,
      'keep-build': false,
      'preset': false,
    };

    for (final setter in setters) {
      // Check if setter is any
      final hasSetter =
          modifiableArgs.any((element) => element.contains(setter));

      if (hasSetter) {
        // Retain only elements without this value
        modifiableArgs.retainWhere((element) => !element.contains(setter));

        if (setter == 'keep-pre' ||
            setter == 'keep-build' ||
            setter == 'preset') {
          modifiableMap.update(setter, (value) => true);
        } else {
          modifiableMap.update(
            setter,
            (value) => args
                .firstWhere((element) => element.contains(setter))
                .split('=')
                .last,
          );
        }
      }
    }

    return (
      args: modifiableArgs,
      path: modifiableMap['set-path'],
      version: modifiableMap['set-version'],
      build: modifiableMap['set-build'],
      prerelease: modifiableMap['set-prerelease'],
      keepPre: modifiableMap['keep-pre'],
      keepBuild: modifiableMap['keep-build'],
      preset: modifiableMap['preset'],
      // set-version defaults presetVersion to true
      presetOnlyVersion: modifiableMap['set-version'] != null
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
