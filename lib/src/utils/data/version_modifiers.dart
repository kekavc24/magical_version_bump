import 'package:args/args.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';

/// Stores the version modifier flags from commands such as:
///   * `set-version`
///   * `set-prerelease`
///   * `set-build`
///   * `keep-pre`
///   * `keep-build`
abstract class VersionModifiers {
  VersionModifiers({
    required this.presetType,
    required this.version,
    required this.prerelease,
    required this.build,
    required this.keepPre,
    required this.keepBuild,
  });

  /// Preset type
  final PresetType presetType;

  /// Version
  final String? version;

  /// Prerelease
  final String? prerelease;

  /// Build info
  final String? build;

  /// Whether to keep old prerelease info
  final bool keepPre;

  /// Whether to keep old build info
  final bool keepBuild;
}

/// Default class just returns the abstract class
class DefaultVersionModifiers extends VersionModifiers {
  DefaultVersionModifiers({
    required super.presetType,
    required super.version,
    required super.prerelease,
    required super.build,
    required super.keepPre,
    required super.keepBuild,
  });

  /// Basic factory
  factory DefaultVersionModifiers.fromArgResults(ArgResults argResults) {
    return DefaultVersionModifiers(
      presetType: _sortPreset(argResults),
      version: argResults.setVersion,
      prerelease: argResults.setPrerelease,
      build: argResults.setBuild,
      keepPre: argResults.keepPre,
      keepBuild: argResults.keepBuild,
    );
  }

  static PresetType _sortPreset(ArgResults argResults) {
    final currentPreset = argResults.checkPreset();

    // If preset is none or version, confirm if any of build or prerelease was
    // set
    if (currentPreset == PresetType.none ||
        currentPreset == PresetType.version) {
      return argResults.setBuild != null || argResults.setPrerelease != null
          ? PresetType.all
          : currentPreset;
    }

    return currentPreset;
  }
}

/// Bump command version modifiers. Checks for:
///   * `preset` everything or just the version
///   * `strategy`
class BumpVersionModifiers extends VersionModifiers {
  BumpVersionModifiers({
    required super.presetType,
    required super.version,
    required super.prerelease,
    required super.build,
    required super.keepPre,
    required super.keepBuild,
    required this.strategy,
  });

  /// Basic factory
  factory BumpVersionModifiers.fromArgResults(ArgResults argResults) {
    return BumpVersionModifiers(
      presetType: argResults.checkPreset(),
      version: argResults.setVersion,
      prerelease: argResults.setPrerelease,
      build: argResults.setBuild,
      keepPre: argResults.keepPre,
      keepBuild: argResults.keepBuild,
      strategy: argResults.strategy,
    );
  }

  /// Modify Strategy
  final ModifyStrategy strategy;
}
