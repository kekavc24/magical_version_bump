import 'package:args/args.dart';

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
}
