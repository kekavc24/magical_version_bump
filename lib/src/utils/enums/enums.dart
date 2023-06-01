/// Defines versioning strategy the tool will use as specified by user
///
///   [absolute] - treats each version as an independent number
///
///   [relative] - normal versioning as specified by SEMVER
enum ModifyStrategy { absolute, relative }

/// Defines whether version will be bumped up or down by 1
enum BumpType { up, down }
