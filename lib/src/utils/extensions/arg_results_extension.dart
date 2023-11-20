part of 'extensions.dart';

/// Extension group with general info
extension SharedArgResults on ArgResults {
  PathInfo get pathInfo {
    // Read paths before hand
    final paths = this['directory'];

    return (
      requestPath: this['request-path'] as bool,
      paths: paths is List<String> ? paths : [paths as String],
    );
  }
}

/// Extension group with version modifier results
extension VersionModifierResults on ArgResults {
  /// Check set version
  String? get setVersion => this['set-version'] as String?;

  /// Check set prerelease
  String? get setPrerelease => this['set-prerelease'] as String?;

  /// Check set build
  String? get setBuild => this['set-build'] as String?;

  /// Check whether to retain prerelease
  bool get keepPre => this['keep-pre'] as bool;

  /// Check whether to retain build
  bool get keepBuild => this['keep-build'] as bool;

  /// Check targets
  List<String> get targets => this['targets'] as List<String>;

  /// Check strategy
  ModifyStrategy get strategy => this['strategy'] == 'absolute'
      ? ModifyStrategy.absolute
      : ModifyStrategy.relative;

  /// Check preset
  PresetType checkPreset({required bool ignoreFlag}) {
    // Check preset flag. Set to false if we want to ignore
    final preset = ignoreFlag ? !ignoreFlag : this['preset'] as bool;

    // Preset only version if preset is false & version is not null
    final presetOnlyVersion = !preset && this['set-version'] != null;

    if (presetOnlyVersion) return PresetType.version;

    if (preset) return PresetType.all;

    return PresetType.none;
  }
}
