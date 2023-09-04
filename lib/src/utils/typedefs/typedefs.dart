/// Reason why an error was thrown:
///
/// * Key - title (shown in progress)
/// * Value - error (logged in console)
typedef InvalidReason = MapEntry<String, String>;

/// Custom dictionary
///
/// * `List<String>` - all roots keys preceding data
typedef Dictionary = ({List<String> rootKeys, bool append, dynamic data});

/// Recursive return value
/// 
/// * `failed` - whether operation to add value failed
/// * `reason` - what key caused the recursive update to fail
/// * `finalDepth` - how far deep the recursive function managed to reach
/// * `updatedValue` - final value updated. Will be null when `finalDepth` is  
/// not 0 and when operation failed
/// 
typedef NestedUpdate = ({
  bool failed,
  String? failedReason,
  int finalDepth,
  Map<String, dynamic>? updatedValue,
});
