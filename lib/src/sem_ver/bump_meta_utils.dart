part of 'semver.dart';

/// Searches and returns the valid index and the specific metadata at the
/// index.
///
/// If [indexOrPrefix] is a [String], then the first instance and its index
/// is returned. If not found, -1 is returned as the index. Returns `null` if
/// empty.
///
/// If [indexOrPrefix] is [int], the value returned may be `null` if the index
/// is not within the list.
(int index, dynamic valueAtIndex) _getPositionInMetadata(
  List<dynamic> metadata,
  dynamic indexOrPrefix,
) {
  if (indexOrPrefix is String?) {
    return indexOrPrefix == null || indexOrPrefix.isEmpty
        ? (-1, null)
        : metadata.indexed.firstWhere(
            (value) => value.$2.toString().startsWith(indexOrPrefix),
            orElse: () => (-1, indexOrPrefix),
          );
  }

  final length = metadata.length;
  final index = min(length, indexOrPrefix as int);
  return (index, index == length ? null : metadata[index]);
}

/// Extracts the trailing modifier that indicates how the metadata should be
/// bumped and/or modified
_TrailingInfo _extractTrailingModInfo(String trailingModifier) {
  const pattern = '.';
  final firstIsPeriod = trailingModifier.startsWith(pattern);

  // Split after first period if present
  final modifierToSplit =
      firstIsPeriod ? trailingModifier.safeSubstring(1) : trailingModifier;

  return (firstIsPeriod, modifierToSplit.split(pattern));
}

/// Increments a [value] based on its type.
///
/// Updates on a [String] are rewritten to `myString-<integer>`
dynamic _updateInPlace(dynamic value) {
  if (value is int) return value + 1;

  final lastIndex = (value as String).length;
  var lastIndexOfInt = lastIndex;

  // Walk string backwards till we find the full integer
  while (lastIndexOfInt != 0) {
    final possibleIndex = lastIndexOfInt - 1;

    if (int.tryParse(value[possibleIndex]) != null) {
      lastIndexOfInt = possibleIndex;
      continue;
    }

    break;
  }

  if (lastIndexOfInt == lastIndex) return '$value-1';
  return '${value.safeSubstring(0, lastIndexOfInt)}'
      '-${int.parse(value.safeSubstring(lastIndexOfInt)) + 1}';
}

/// Removes and appends a trailing `1` if the last element is an empty string.
List<dynamic> _pruneTrailing(List<dynamic> list) {
  final last = list.lastOrNull;

  if (last != null && last is String && last.trim().isEmpty) {
    list
      ..removeLast()
      ..add(1);
  }

  return list;
}

/// Custom compare for swapping metadata
bool _compareLoose(dynamic existing, dynamic replacement) {
  if (existing is int && replacement is int) {
    return existing == replacement;
  }

  if (existing is String && replacement is String) {
    return existing.startsWith(replacement);
  }

  return false;
}

/// Modifies metadata if the trailing modifier had leading period `.`
void _leadingPeriodMod(
  List<dynamic> metadata, {
  required bool accessorHasIndex,
  required bool hasAccessor,
  required dynamic accessor,
  required String trailingModifier,
  required List<dynamic> oldMetadata,
  required List<dynamic> metadataToAdd,
}) {
  // If we have an index for the accessor. Within the existing metadata range
  if (accessorHasIndex) {
    switch (trailingModifier) {
      /// build{A}{.}
      ///
      /// - If A is present, update inlined. Bump `int` by 1 while strings are
      ///   rewritten as "A-<int>"
      case '.' when hasAccessor:
        metadata.add(_updateInPlace(accessor));

      /// build{A}{.}
      ///
      /// - If A is absent, add 1 at the end.
      case '.' when !hasAccessor:
        metadata.add(1);

      /// build{A}{.value(.value)*}
      ///
      /// - If A is present, add all after A
      /// - If A is absent, add at the end of current metadata. Moreso when
      ///   the index provided exceed metadata length
      default:
        if (hasAccessor) metadata.add(accessor);
        metadata.addAll(metadataToAdd);
    }

    return;
  }

  /// If no accessor is present, we add all new metadata to the existing
  /// metadata instead
  if (!hasAccessor) {
    metadata
      ..addAll(oldMetadata)

      // A trailing period always results in a "1" appended
      ..addAll(metadataToAdd.isEmpty ? [1] : metadataToAdd);

    return;
  }

  // Degenerates to adding at the end
  _addAtEnd(
    metadata,
    hasAccessor: true,
    accessor: accessor,
    metadataToAdd: metadataToAdd,
  );
}

/// Replaces an accessor or updates it in place if it matches the leading
/// value of [metadataToAdd].
void _replaceOrUpdateInPlace(
  List<dynamic> metadata, {
  required dynamic accessor,
  required List<dynamic> metadataToAdd,
}) {
  /// build{A}{value(.value)*}
  ///
  /// - A is present within the metadata.
  final metaAtHead = metadataToAdd.firstOrNull;

  if (metaAtHead != null) {
    /// If equal to A, update in-place. Otherwise swap them. And add any
    /// remaining metadata
    metadata
      ..add(
        _compareLoose(accessor, metaAtHead)
            ? _updateInPlace(accessor)
            : metaAtHead,
      )
      ..addAll(metadataToAdd.skip(1));
  }
}

/// Replaces/adds to any existing metadata.
void _addAtEnd(
  List<dynamic> metadata, {
  required bool hasAccessor,
  required dynamic accessor,
  required List<dynamic> metadataToAdd,
}) {
  if (hasAccessor) metadata.add(accessor);
  metadata.addAll(metadataToAdd);
}
