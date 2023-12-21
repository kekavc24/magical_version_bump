part of 'console_printer.dart';

// Huge thanks to [Nathan Friend](https://gitlab.com/nfriend). His project
// [tree-online](https://gitlab.com/nfriend/tree-online) was an
// inpiration for this.

enum CharSet { utf8, ascii }

/// EXtracts a key/list of keys from a value based on [Origin].
///
/// The [Origin] guarantees that a value will be unique and prevent duplication
/// as various keys/values/pairs may have been found/replaced from different
/// keys.
T _extractKey<T>({required Origin origin, required dynamic value}) {
  // For value, return as is
  if (origin == Origin.value) {
    return TrackerKey(key: value as String, origin: origin) as T;
  }

  // For key, we get a list of values
  if (origin == Origin.key) {
    return (value as Iterable<String>)
        .map((e) => TrackerKey(key: e, origin: Origin.key))
        .toList() as T;
  }

  // For pair, we have to save a dual key
  return (value as Map<String, String>)
      .entries
      .map(DualTrackerKey.fromMapEntry)
      .toList() as T;
}

/// Extracts all keys from
List<TrackerKey> _getKeysFromMatch(MatchedNodeData matchedNodeData) {
  return <TrackerKey>[
    // Extract sole key for value
    _extractKey<TrackerKey>(
      origin: Origin.value,
      value: matchedNodeData.matchedValue,
    ),

    // Extract list of keys from matched keys
    ..._extractKey<List<TrackerKey>>(
      origin: Origin.key,
      value: matchedNodeData.matchedKeys,
    ),

    // Extract list of dual keys from map entry.
    ..._extractKey<List<DualTrackerKey>>(
      origin: Origin.pair,
      value: matchedNodeData.matchedPairs,
    ),
  ];
}

/// Wraps matches with a lightGreen [AnsiCode] for matches
String wrapMatches({required String path, required List<String> matches}) {
  /// Wrap any match with green.
  return path
      .split('/')
      .map((e) => matches.contains(e) ? lightGreen.wrap(e) : e)
      .join('/');
}

/// Wraps updated values with lightGreen [AnsiCode] and values to be
/// replaced with a lightRed [AnsiCode]
({String oldPath, String updatedPath}) replaceAndWrap({
  required String path,
  required bool replacedKeys,
  required Map<String, String> replacements,
}) {
  final replaced = <String>[];

  final tempPath = path.split('/');
  final lastIndex = tempPath.length - 1;

  ///
  /// Number of elements is equal to last index i.e.
  ///
  /// if index of last element is 3, list has 4 elements total. So taking 3
  /// gets all elements excluding the last
  final keys = tempPath.take(lastIndex);
  final lastElement = tempPath[lastIndex];

  if (replacedKeys) {
    final oldKeyPath = keys.map((element) {
      // Ignore if we don't need to replace
      if (!replacements.containsKey(element)) {
        replaced.add(element);
        return element;
      }

      // Wrap replacement with light green
      final update = lightGreen.wrap(replacements[element]);
      replaced.add(update!);

      return lightRed.wrap(element)!;
    });
    return (
      oldPath: [...oldKeyPath, lastElement].join('/'),
      updatedPath: [...replaced, lastElement].join('/'),
    );
  }

  // Create old path before swap
  final oldPath = [...keys, lightRed.wrap(lastElement)].join('/');

  // Add all keys & wrapped key
  replaced
    ..addAll(keys)
    ..add(lightGreen.wrap(replacements[lastElement])!);

  return (oldPath: oldPath, updatedPath: replaced.join('/'));
}

/// Used to separate different children. This is mainly used to show clear
/// distinction when showing values replaced in various paths.
String _childSeparator({
  CharSet charSet = CharSet.utf8,
}) {
  final separator = charSet == CharSet.utf8 ? '│' : '|';

  return lightYellow.wrap(separator)!;
}

/// Used to separate value found/replaced with its count
String _countSeparator({CharSet charSet = CharSet.utf8}) {
  return charSet == CharSet.utf8 ? '──' : '--';
}

/// A tree-like string denoting a branch in which a value was found or replaced.
///
/// [charSet] - defaults to `utf8` if not provided.
///
String getBranch({
  CharSet charSet = CharSet.utf8,
  bool isLastChild = false,
}) {
  // Branch based on level
  final branch = switch (charSet) {
    CharSet.utf8 when isLastChild => '└──',
    CharSet.ascii when isLastChild => '`--',
    CharSet.utf8 => '├──',
    CharSet.ascii => '|--'
  };

  return lightYellow.wrap(branch)!;
}

/// Creates a file header based on Console format
String createHeader({
  required ConsoleViewFormat format,
  required dynamic fileInfo,
  bool? useFileName,
}) {
  var header = '';

  if (format == ConsoleViewFormat.live) {
    header = '\n-- File at index -> $fileInfo --';
  } else {
    useFileName ??= false;
    header =
        "\n-- Aggregated Info for : ${useFileName ? '$fileInfo' : 'all files'}";
  }

  return lightMagenta.wrap('$header\n')!;
}

/// A tree-like string deno

String formatInfo({
  required String key,
  required List<TrackedValue> trackedValues,
  required bool showCount,
  int? count,
}) {
  // Format buffer
  final formatBuffer = StringBuffer();

  // Value used as anchor
  final anchor = showCount ? '$key ${_countSeparator()} ${count ?? 1}' : key;
  final indexOfLast = trackedValues.length - 1; // Index of last element

  /// Check if in replace mode. Replace mode stores value in a
  /// [DualTrackerKey] with old path and new path
  final isReplaceMode = trackedValues.any(
    (element) => element is DualTrackedValue,
  );

  formatBuffer.writeln(lightCyan.wrap(anchor)); // Will always appear first

  // Loop all links and create a tree-like structure
  for (final (index, value) in trackedValues.indexed) {
    // Replace mode has 2 sub branches before the next. Create one for old path
    if (isReplaceMode) {
      final oldPathBranch = getBranch(); // Never last
      formatBuffer.writeln('$oldPathBranch ${value.key}');
    }

    // Check if last child
    final isLastChild = index == indexOfLast;

    // Access value instead of key in replacemode
    final twigToUse =
        isReplaceMode ? (value as DualTrackerKey).value : value.key;

    final defaultBranch = getBranch(isLastChild: isLastChild);

    formatBuffer.writeln('$defaultBranch $twigToUse');

    // Write pipe separator for replace mode
    if (isReplaceMode && !isLastChild) {
      formatBuffer.writeln(_childSeparator());
    }
  }

  formatBuffer.writeln(); // Add empty line
  return formatBuffer.toString();
}
