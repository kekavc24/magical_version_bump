import 'package:yaml/yaml.dart';

/// Reason why an error was thrown:
///
/// * Key - title (shown in progress)
/// * Value - error (logged in console)
typedef InvalidReason = MapEntry<String, String>;

/// Custom dictionary
///
/// * `List<String>` - all roots keys preceding data
typedef Dictionary = ({List<String> rootKeys, bool append, dynamic data});

/// Path info from commands
typedef PathInfo = ({bool requestPath, String path});

/// File output after file has been read
typedef FileOutput = ({String file, YamlMap fileAsMap});

/// Keys to find in yaml/json file
typedef KeysToFind = ({
  /// Whether to treat all keys as a group such that they all have to exist
  /// not just one of them
  bool areGrouped,

  /// Whether to ensure they are in the defined order
  bool strictOrder,

  /// Keys to find
  List<String> keys,
});

/// List of values to find in yaml/json file
typedef ValuesToFind = List<String>;

/// Map of pairs to find in yaml/json file
typedef PairsToFind = Map<String, String>;
