part of 'formatter.dart';

// TODO: Add documentation
final class FormatterTracker<F extends TrackerKey<String>>
    extends SingleValueTracker<String, List<F>>
    with MapHistory<int, String, dynamic, List<F>> {
  FormatterTracker({int? maxTolerance}) : maxTolerance = maxTolerance ?? 0;

  /// Current cursor for current file info being tracked
  int currentCursor = 0;

  /// Indicates the max times to tolerate this cursor as the key before
  /// swapping to a new cursor(file index). Think cache miss/hit. Max is [2]
  /// but currently at [0].
  ///
  /// Future versions may include some concurrency, thus values may come in
  /// any order
  int currentTolerance = 0;

  /// Currently at 0 as current implementations are sequential/blocking.
  final int maxTolerance;

  /// Saves values to this tracker
  void add({
    required int fileIndex,
    required List<TrackerKey<String>> keys,
    required F value,
  }) {
    final useLocalCopy = currentCursor == fileIndex;

    // Increment tolerance incase not same index
    if (!useLocalCopy) currentTolerance++;

    // Fallback to empty map incase not in history
    final copy = useLocalCopy ? trackerState : getFromHistory(fileIndex) ?? {};

    for (final key in keys) {
      copy.update(
        key,
        (current) => [...current, value],
        ifAbsent: () => [value],
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
    required Map<TrackerKey<String>, List<F>> state,
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
