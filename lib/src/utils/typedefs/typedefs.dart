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
