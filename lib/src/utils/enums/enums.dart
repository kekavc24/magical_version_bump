/// Defines versioning strategy the tool will use as specified by user
///
///   [absolute] - treats each version as an independent number
///
///   [relative] - normal versioning as specified by SEMVER
enum ModifyStrategy { absolute, relative }

/// Filetype being read
enum FileType { yaml, json, unknown }

/// Preset type when bumping version
enum PresetType {
  /// No preset was used
  none,

  /// Set only version
  version,

  /// Preset version, prerelease & build number
  all;
}

/// Amount of values that match condition in list of string
enum MatchCount {
  /// No match
  none,

  /// At least 1 or more
  some,

  /// All values match
  all
}

/// Type of update to map
enum UpdateMode {
  /// Adds value to terminal end
  append,

  /// Replaces a single value
  replace,

  /// Removes and replaces old value with a new one
  overwrite
}
