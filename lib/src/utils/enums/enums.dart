/// Defines versioning strategy the tool will use as specified by user
///
///   [absolute] - treats each version as an independent number
///
///   [relative] - normal versioning as specified by SEMVER
enum ModifyStrategy { absolute, relative }

/// Filetype being read
enum FileType { yaml, json, unknown }
