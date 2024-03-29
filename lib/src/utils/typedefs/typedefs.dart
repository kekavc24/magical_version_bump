import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:yaml/yaml.dart';

/// Reason why an error was thrown:
///
/// * Key - title (shown in progress)
/// * Value - error (logged in console)
typedef InvalidReason = MapEntry<String, String>;

/// Custom dictionary
///
/// * `List<String>` - all roots keys preceding data
typedef Dictionary = ({
  List<String> rootKeys,
  UpdateMode updateMode,
  dynamic data,
});

/// Path info from commands
typedef PathInfo = ({bool requestPath, List<String> paths});

/// File output after file has been read
typedef FileOutput = ({String file, YamlMap fileAsMap});

/// Keys to find in yaml/json file
typedef KeysToFind = ({
  /// Desired Order type
  OrderType orderType,

  /// Keys to find
  List<String> keys,
});

/// List of values to find in yaml/json file
typedef ValuesToFind = List<String>;

/// Map of pairs to find in yaml/json file
typedef PairsToFind = Map<String, String>;

/// Simple name for Map of keys and their replacements
typedef KeyAndReplacement = PairsToFind;

/// An output from recursive function call on a list
typedef RecursiveListOutput = ({bool didModify, List<dynamic> modified});

/// Check if collections match. Check for order too.
bool collectionsMatch(dynamic e1, dynamic e2) =>
    const DeepCollectionEquality().equals(e1, e2);

/// Check if collections match. Ignores order
bool collectionsUnorderedMatch(dynamic e1, dynamic e2) =>
    const DeepCollectionEquality.unordered().equals(e1, e2);

/// Denotes aggregate type to use, count and whether to aggregation type to
/// each output
typedef Aggregator = ({
  AggregateType type,
  bool applyToEachArg,
  bool applyToEachFile,
  int? count,
});

/// List of values in arguments
typedef ParsedValues = List<String>;

/// List of list of values in arguments
typedef ListOfParsedValues = List<List<String>>;
