// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:args/args.dart';

import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';

/// Stores the version modifier flags from commands such as:
///   * `set-version`
///   * `set-prerelease`
///   * `set-build`
///   * `keep-pre`
///   * `keep-build`
class VersionModifiers {
  /// Default constructor
  VersionModifiers.fromArgResults(
    ArgResults argResults, {
    bool initializePreset = true,
  }) {
    version = argResults.setVersion;
    if (initializePreset) presetType = _sortPreset(argResults);
    prerelease = argResults.setPrerelease;
    build = argResults.setBuild;
    keepPre = argResults.keepPre;
    keepBuild = argResults.keepBuild;
  }

  /// Constructor that adds strategy for `bump` subcommand
  factory VersionModifiers.fromBumpArgResults(ArgResults argResults) {
    return VersionModifiers.fromArgResults(argResults, initializePreset: false)
      ..presetType = argResults.checkPreset(ignoreFlag: false)
      ..strategy = argResults.strategy();
  }

  /// Preset type
  late final PresetType presetType;

  /// Version
  late final String? version;

  /// Prerelease
  late final String? prerelease;

  /// Build info
  late final String? build;

  /// Whether to keep old prerelease info
  late final bool keepPre;

  /// Whether to keep old build info
  late final bool keepBuild;

  /// Modify Strategy
  late final ModifyStrategy strategy;

  static PresetType _sortPreset(ArgResults argResults) {
    final currentPreset = argResults.checkPreset(ignoreFlag: true);

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
