part of 'formatter.dart';

/// A tracker used by [NodePathFormatter] and any of its subclasses to track
/// paths formatted by linking it to a value wrapped by a [TrackerKey].
///
/// History is linked to a file index.
final class FormatterTracker
    extends SingleValueTracker<String, List<FormattedPathInfo>>
    with MapHistory<int, String, dynamic, List<FormattedPathInfo>> {
  FormatterTracker({int? maxTolerance}) : maxTolerance = maxTolerance ?? 0;

  /// Current cursor for current file info being tracked
  int currentCursor = 0;

  /// Indicates the current tolerance state of this tracker, in that, how
  /// many times was the state fetched from history/new state.
  int currentTolerance = 0;

  /// Indicates the max times to tolerate this cursor as the key before
  /// swapping to a new cursor(file index). Think cache miss/hit. Max is [2]
  /// but currently at [0].
  ///
  /// Future versions may include some concurrency, thus values may come in
  /// any order
  final int maxTolerance;

  /// Saves values to this tracker
  void add({
    required int fileIndex,
    required List<TrackerKey<String>> keys,
    required FormattedPathInfo pathInfo,
  }) {
    final useLocalCopy = currentCursor == fileIndex;

    // Increment tolerance incase not same index
    if (!useLocalCopy) currentTolerance++;

    // Fallback to empty map incase not in history
    final copy = useLocalCopy ? trackerState : getFromHistory(fileIndex) ?? {};

    for (final key in keys) {
      copy.update(
        key,
        (current) => [...current, pathInfo],
        ifAbsent: () => [pathInfo],
      );
    }

    if (!useLocalCopy) {
      _attempSwap(
        reachedMaxTolerance: currentTolerance > maxTolerance,
        fileIndex: fileIndex,
        state: copy,
      );
    }
  }

  /// Swaps the current cursor to point to an updated if [maxTolerance] is
  /// reached. Otherwise, saves current cursor to history for accurate
  /// tracking
  void _attempSwap({
    required bool reachedMaxTolerance,
    required int fileIndex,
    required Map<TrackerKey<String>, List<FormattedPathInfo>> state,
  }) {
    if (reachedMaxTolerance) {
      reset(cursor: currentCursor);
      currentCursor = fileIndex;
      currentTolerance = 0;
      trackerState.addAll(state);
      dropCursor(fileIndex);
    } else {
      history.putIfAbsent(fileIndex, () => state);
    }
  }
}
