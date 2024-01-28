part of 'replacer_manager.dart';

typedef TrackerOutput = ({int fileNumber, List<MatchedNodeData> matches});

final class ReplacerTracker extends SingleValueTracker<String, MatchedNodeData>
    with MapHistory<int, String, dynamic, MatchedNodeData> {
  ReplacerTracker() : _isRename = true;

  /// Current walksubcommand type. Determines which path to store
  final bool _isRename;

  /// Keeps track of current file number so far
  int _internalCursor = 0;

  /// Adds all matches and removes any duplicates. Helps prevent any recursions
  /// on same path
  void addAll(List<FindManagerOutput> outputs) {
    for (final output in outputs) {
      _addMatch(output);
    }
  }

  /// Adds a single match.
  void _addMatch(FindManagerOutput output) {
    if (_internalCursor != output.currentFile) {
      reset(cursor: _internalCursor); // Save current history
      _internalCursor = output.currentFile; // Change cursor to current file
    }

    final matchedNode = output.data;

    /// A node is usually indexed to the terminal value. While this is great
    /// for replacing values, replacing keys may be cumbersome since:
    ///   1. Values in same list with have the same set of keys
    ///   2. Values in same map will have same set of keys upto the last
    ///      one linking a terminal value
    ///
    /// Recursing to replace the same key a 1000 times? Inefficient!
    ///
    /// This only applies to [WalkSubcommand.rename]. Remove duplicates and
    /// recurse only keys yet to be replaced
    final path =
        _isRename ? matchedNode.getPathToLastKey() : matchedNode.toString();

    trackerState.putIfAbsent(
      createKey(path, origin: Origin.custom),
      () => matchedNode,
    );
  }

  /// Obtains all matches without any duplicate paths.
  ///
  /// NOTE: a full path may be nested in another path but the impact is lower.
  List<TrackerOutput> getMatches() {
    // Reset last tracker
    reset(cursor: _internalCursor);

    return history.entries.fold([], (previousValue, element) {
      previousValue.add(
        (fileNumber: element.key, matches: element.value.values.toList()),
      );
      return previousValue;
    });
  }
}
