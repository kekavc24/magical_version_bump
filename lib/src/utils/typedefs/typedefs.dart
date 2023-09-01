/// Arguments and their respective values
typedef NodesAndValues = Map<String, String>;

/// Reason why an error was thrown:
///
/// * Key - title (shown in progress)
/// * Value - error (logged in console)
typedef InvalidReason = MapEntry<String, String>;

/// Custom dictionary
///
/// [List<String>] - all roots keys preceding data
typedef Dictionary = ({List<String> rootKeys, bool append, dynamic data});
