// Huge thanks to [Nathan Friend](https://gitlab.com/nfriend). His project
// [tree-online](https://gitlab.com/nfriend/tree-online) was an
// inpiration for this.

part of 'formatter.dart';

typedef FormattedPathInfo = ({String path, String? updatedPath});

enum CharSet { utf8, ascii }

/// Magenta for heading for any file names
const headerColor = magenta;

/// Light cyan for value matched with a yaml/json node path.
const anchorColor = lightCyan;

/// Light green for a valid value matched/added in yaml/json node path to
/// terminal value
const matchColor = lightGreen;

/// Light red for any key/value removed from yaml/json node path to
/// terminal value
const replacedColor = lightRed;

/// Light yellow for any branch/related separator
const branchColor = lightYellow;

/// EXtracts a key/list of keys from a value based on [Origin].
///
/// The [Origin] guarantees that a value will be unique and prevent duplication
/// as various keys/values/pairs may have been found/replaced from different
/// keys.
T extractKey<T>({
  required Origin origin,
  required dynamic value,
  bool isReplacement = false,
}) {
  // For value, return as is
  if (origin == Origin.value && !isReplacement) {
    return TrackerKey(key: value as String, origin: origin) as T;
  }

  // For key, we get a list of values
  if (origin == Origin.key || isReplacement) {
    return (value as Iterable<String>)
        .map((e) => TrackerKey(key: e, origin: origin))
        .toList() as T;
  }

  // For pair, we have to save a dual key
  return (value as Map<String, String>)
      .entries
      .map(
        (e) => DualTrackerKey<String, String>.fromEntry(
          entry: e,
          origin: origin,
        ),
      )
      .toList() as T;
}

/// Extracts all keys from
List<TrackerKey<String>> getKeysFromMatch(MatchedNodeData matchedNodeData) {
  final keysForMatch = <TrackerKey<String>>[];

  if (matchedNodeData.matchedValue.isNotEmpty) {
    keysForMatch.add(
      extractKey(
        origin: Origin.value,
        value: matchedNodeData.matchedValue,
      ),
    );
  }

  if (matchedNodeData.matchedKeys.isNotEmpty) {
    keysForMatch.addAll(
      extractKey<List<TrackerKey<String>>>(
        origin: Origin.key,
        value: matchedNodeData.matchedKeys,
      ),
    );
  }

  if (matchedNodeData.matchedPairs.isNotEmpty) {
    keysForMatch.addAll(
      extractKey<List<TrackerKey<String>>>(
        origin: Origin.pair,
        value: matchedNodeData.matchedPairs,
      ),
    );
  }

  return keysForMatch;
}

/// Wraps matches with a lightGreen [AnsiCode] for matches
FormattedPathInfo wrapMatches({
  required String path,
  required List<String> matches,
}) {
  /// Wrap any match with green.
  return (
    path: path
        .split('/')
        .map((e) => matches.contains(e) ? matchColor.wrap(e) : e)
        .join('/'),
    updatedPath: null,
  );
}

/// Wraps updated values with lightGreen [AnsiCode] and values to be
/// replaced with a lightRed [AnsiCode]
FormattedPathInfo replaceAndWrap({
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
      final update = matchColor.wrap(replacements[element]);
      replaced.add(update!);

      return replacedColor.wrap(element)!;
    });
    return (
      path: [...oldKeyPath, lastElement].join('/'),
      updatedPath: [...replaced, lastElement].join('/'),
    );
  }

  // Create old path before swap
  final oldPath = [...keys, replacedColor.wrap(lastElement)].join('/');

  // Add all keys & wrapped key
  replaced
    ..addAll(keys)
    ..add(matchColor.wrap(replacements[lastElement])!);

  return (path: oldPath, updatedPath: replaced.join('/'));
}

/// Used to separate different children. This is mainly used to show clear
/// distinction when showing values replaced in various paths.
String getChildSeparator({
  CharSet charSet = CharSet.utf8,
}) {
  final separator = charSet == CharSet.utf8 ? '│' : '|';

  return branchColor.wrap(separator)!;
}

/// Used to separate value found/replaced with its count
String getCountSeparator({CharSet charSet = CharSet.utf8}) {
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

  return branchColor.wrap(branch)!;
}

/// Creates a file header based on Console format
String createHeader({
  required bool isReplaceMode,
  required String fileName,
  required int countOfMatches,
  required int? countOfReplacements,
}) {
  return headerColor.wrap(
    '''\n** Aggregated Info for ${styleItalic.wrap(fileName)} : Found $countOfMatches matches${isReplaceMode ? ', Replaced $countOfReplacements' : ''} **\n''',
  )!;
}

/// A tree-like view of info for each match/value added. Replace mode stores value in a
/// [DualTrackerKey] with old path and new path
String formatInfo({
  required bool isReplaceMode,
  required String key,
  required List<FormattedPathInfo> formattedPaths,
}) {
  final countOfPaths = formattedPaths.length;

  // Key acts as the "anchor"
  final formatBuffer = StringBuffer(
    anchorColor.wrap(
      '''$key ${getCountSeparator()} ${isReplaceMode ? 'Replaced ' : 'Found '} $countOfPaths\n''',
    )!,
  );

  // Loop all links and create a tree-like structure
  for (final (index, formattedPath) in formattedPaths.indexed) {
    // Replace mode has 2 sub branches before the next. Create one for old path
    if (isReplaceMode) {
      final oldPathBranch = getBranch(); // Never last
      formatBuffer.writeln('$oldPathBranch ${formattedPath.path}');
    }

    final isLastChild = index == (countOfPaths - 1);

    // Use updated path in replace mode.
    final branchInfo =
        isReplaceMode ? formattedPath.updatedPath! : formattedPath.path;

    final defaultBranch = getBranch(isLastChild: isLastChild);

    formatBuffer.writeln('$defaultBranch $branchInfo');

    // Write pipe separator for replace mode
    if (isReplaceMode && !isLastChild) {
      formatBuffer.writeln(getChildSeparator());
    }
  }

  formatBuffer.writeln(); // Add empty line
  return formatBuffer.toString();
}
