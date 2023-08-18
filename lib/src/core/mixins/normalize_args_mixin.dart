import 'package:magical_version_bump/src/core/exceptions/command_exceptions.dart';

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
    'preset',
    'with-path',
  ];

  /// Normalize arguments. Remove '-' or '--' present.
  List<String> normalizeArgs(List<String> args) {
    // Args must not be empty
    if (args.isEmpty) {
      throw MagicalException(violation: 'No arguments found');
    }

    final sanitizedArgs = args.map((e) {
      var mod = e.replaceFirst(RegExp('--'), '');

      if (mod[0] == '-') mod = mod.replaceFirst(RegExp('-'), '');

      return mod.isEmpty ? 'null' : mod;
    }).toList();

    return sanitizedArgs;
  }

  /// Check whether user set/used any `setter` flags/options
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
    bool requestPath,
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
      'with-path': false,
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
            setter == 'preset' ||
            setter == 'with-path') {
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

    final preset = modifiableMap['preset'] as bool;
    final requestPath = modifiableMap['with-path'] as bool;

    return (
      args: modifiableArgs,
      path: modifiableMap['set-path'],
      version: modifiableMap['set-version'],
      build: modifiableMap['set-build'],
      prerelease: modifiableMap['set-prerelease'],
      keepPre: modifiableMap['keep-pre'],
      keepBuild: modifiableMap['keep-build'],
      preset: preset,

      // set-version defaults presetOnlyVersion to true if preset is not true
      presetOnlyVersion: modifiableMap['set-version'] != null && !preset,

      // Only true if setPath is null & with-path is true
      requestPath: modifiableMap['set-path'] == null && requestPath,
    );
  }
}
