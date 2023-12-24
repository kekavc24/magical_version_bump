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

/// Type of subcommand that may have been triggered
enum WalkSubCommandType {
  find(isFinder: true),
  search(isFinder: true),
  rename(isFinder: false),
  replace(isFinder: false);

  const WalkSubCommandType({required this.isFinder});

  final bool isFinder;
}

/// View format for printing values found by `Finder` or `MagicalReplacer`
enum ConsoleViewFormat {
  /// Grouped by value found or by value replaced
  grouped,

  /// Live preview as they are found/replaced
  live,

  /// Hide output. Only available when replacing values
  hide
}

/// Type of ordering based on a list of targets
enum OrderType {
  /// At least one of any
  loose,

  /// All present
  grouped,

  /// All present and in exact order specified
  strict
}

/// Aggregation type based on count
enum AggregateType {
  /// Only first matching value
  first,

  /// Count of values
  count,

  /// Find all
  all;
}

/// Indicates origin of a value
enum Origin { key, value, pair, custom }
