import 'package:args/args.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';

/// This mixin normalizes arguments passed passed in by user
mixin NormalizeArgs {
  /// Check for path flags & options
  ///
  /// * `requestPath` - Whether to request the path from user, interactively
  /// * `path` - Path to yaml/json file. Defaults to pubspec.yaml
  ///
  ({bool requestPath, String path}) checkPath(ArgResults argResults) {
    return (
      requestPath: argResults['request-path'],
      path: argResults['directory'],
    );
  }

  /// Checks for any custom modifications/preferences for version
  ///
  /// * `preset` - whether to set any version, build or prerelease info
  /// * `presetOnlyVersion` - whether to preset only the version
  /// * `version` - version to set
  /// * `prerelease` - prerelease version to set
  /// * `build` - build metadata to set
  /// * `keepPre` - whether to retain old prerelease info
  /// * `keepBuild` - whether to retain old build metadata
  ({
    bool preset,
    bool presetOnlyVersion,
    String? version,
    String? prerelease,
    String? build,
    bool keepPre,
    bool keepBuild,
  }) checkForVersionModifiers(
    ArgResults argResults, {
    required bool checkPreset,
  }) {
    final preset = checkPreset ? argResults['preset'] as bool : checkPreset;

    return (
      preset: preset,

      // set-version defaults presetOnlyVersion to true if preset is not true
      presetOnlyVersion: argResults['set-version'] != null && !preset,

      version: argResults['set-version'],
      prerelease: argResults['set-prerelease'],
      build: argResults['set-build'],
      keepPre: argResults['keep-pre'],
      keepBuild: argResults['keep-build'],
    );
  }

  /// Extract dictionaries/lists
  Dictionary extractDictionary(String parsedValue, {required bool append}) {
    ///
    /// Format is "key=value,value" or "key=value:value"
    ///
    /// Should never be empty
    if (parsedValue.isEmpty) {
      throw MagicalException(
        violation: 'The root key cannot be empty/null',
      );
    }

    // Must have 2 values, the keys & value(s)
    final keysAndValue = parsedValue.splitAndTrim('=');
    final hasNoBlanks = keysAndValue.every((element) => element.isNotEmpty);

    if (keysAndValue.length != 2 || !hasNoBlanks) {
      throw MagicalException(
        violation: 'Invalid keys and value pair at "$parsedValue"',
      );
    }

    /// Format for specifying more than 1 key is using "|" as a separator
    ///
    /// i.e. `rootKey`|`nextKey`|`otherKey`
    final keys = keysAndValue.first.splitAndTrim('|').retainNonEmpty();

    /// Format for specifying more than 1 value is ","
    ///
    /// i.e `value`,`nextValue`,`otherValue`
    final values = keysAndValue.last.splitAndTrim(',').retainNonEmpty();

    final isMappy = values.first.contains(':');

    /// If more than one value is passed in, we have to check all follow
    /// the same format.
    ///
    /// The first value determines the format the rest should follow!
    if (values.length > 1) {
      final allFollowFormat = values.every(
        (element) => isMappy ? element.contains(':') : !element.contains(':'),
      );

      if (!allFollowFormat) {
        throw MagicalException(
          violation: 'Mixed format at $parsedValue',
        );
      }
    }

    if (isMappy) {
      final valueMap = values.fold(
        <String, String>{},
        (previousValue, element) {
          final mappedValues = element.splitAndTrim(':');
          previousValue.update(
            mappedValues.first,
            (value) => mappedValues.last.isEmpty ? 'null' : mappedValues.last,
            ifAbsent: () =>
                mappedValues.last.isEmpty ? 'null' : mappedValues.last,
          );
          return previousValue;
        },
      );

      return (rootKeys: keys.toList(), append: append, data: valueMap);
    }

    return (
      rootKeys: keys.toList(),
      append: append,
      data: values.length == 1 ? values.first : values.toList(),
    );
  }
}
