part of 'semver.dart';

final _metadataRegex = RegExp(r'^[0-9A-Za-z-]+$');

typedef _TrailingInfo = (
  bool startsWithPeriod,
  List<String> trailingMeta,
);

/// Compares the `prerelease` or `build` metadata of 2 [SemVer] versions
int compareMetadata(List<dynamic> thiz, List<dynamic> other) {
  final leftSize = thiz.length;
  final rightSize = other.length;

  /// A larger set of pre-release fields has a higher precedence than a
  /// smaller set
  if (leftSize > rightSize) return 1;
  if (rightSize > leftSize) return -1;

  for (var index = 0; index < leftSize; index++) {
    final left = thiz[index];
    final right = other[index];

    if (left == right) continue;

    /// Rules by `SemVer`:
    ///   1. Identifiers consisting of only digits are compared numerically.
    ///   2. Identifiers with letters or hyphens are compared lexically in
    ///      ASCII sort order.
    ///   3. Numeric identifiers always have lower precedence than non-numeric
    ///      identifiers.
    final rightIsInt = right is int;

    switch (left) {
      case final int lInt:
        {
          if (rightIsInt) return lInt.compareTo(right);
          return -1;
        }

      default:
        {
          if (rightIsInt) return 1;
          return (left as String).compareTo(right as String);
        }
    }
  }
  return 0;
}

/// Splits the dot-separated `prerelease` or `build` metadata.
void splitMetadata(
  String metadata, {
  required void Function(Iterable<dynamic> data) callback,
  //required bool Function(String value) throwErrorIf,
  required Exception exception,
}) =>
    callback(
      metadata.split('.').map((value) {
        if (!_metadataRegex.hasMatch(value)) {
          throw exception;
        }

        return int.tryParse(value) ?? value;
      }),
    );

/// Represents a valid [SemVer] version target that is to be bumped.
typedef SemVerTarget = ({
  String target,
  dynamic indexOrPrefix,
  String? trailingModifier,
});

/// [SemVer] targets that can be bumped
final _allowedTargets = <String>{
  'major',
  'minor',
  'patch',
  'build',
  'prerelease',
};

/// Parses the targets as defined by [_allowedTargets].
final _allowedTargetsParser = _allowedTargets.map(string).toChoiceParser();

/// Flattens and indicates the current parser should skip enclosing `{}`
/// characters.
Parser _enclosedParser(Parser toEnclose) =>
    toEnclose.flatten().skip(before: char('{'), after: char('}'));

/// Parses an accessor that has a digit
final _indexAsPosition = _enclosedParser(digit().plus());

/// Parses any valid metadata that qualifies as valid `SemVer` prerelease and
/// build metadata
final _metadataParser = pattern('0-9A-Za-z-').star();

/// Parses an accessor that qualifies as valid `SemVer` prerelease and build
/// metadata
final _leadingPrefixParser = _enclosedParser(_metadataParser);

/// Parses a modifier that qualifies as valid `SemVer` prerelease and build
/// metadata optionally separated by `.`.
final _trailingPrefixParser = _enclosedParser(
  [
    _metadataParser.optional(),
    char('.').seq(_metadataParser.optional()).star(),
  ].toSequenceParser(),
);

/// Parses a valid SemVer target to be parsed
SemVerTarget parseSemVerTarget(String target) {
  final parser = <Parser>[
    _allowedTargetsParser,
    _indexAsPosition.or(_leadingPrefixParser).optional(),
    _trailingPrefixParser.optional(),
  ].toSequenceParser();

  final parsed = parser.allMatches(target).flattened;

  if (parsed.isEmpty) {
    throw FormatException(
      'A valid target must be provided. At least one of $_allowedTargets',
      target,
    );
  }

  final [bumpTarget, indexOrPrefix, trailingModifier] = parsed.toList();

  return (
    target: bumpTarget,
    indexOrPrefix: int.tryParse('$indexOrPrefix') ?? indexOrPrefix,
    trailingModifier: trailingModifier,
  );
}

/// Bumps a valid [SemVer] version based on the provided [target].
SemVer bumpVersion(
  String version, {
  required String target,
  bool canCompareBuild = true,
}) =>
    bumpSemVerWithString(
      SemVer.parse(version, canCompareBuild: canCompareBuild),
      target,
    );

SemVer bumpSemVerWithString(SemVer version, String target) =>
    bumpSemVer(version, parseSemVerTarget(target));

/// Bumps a SemVer [version] based on a provided [semVerTarget]
SemVer bumpSemVer(SemVer version, SemVerTarget semVerTarget) {
  final (:target, :indexOrPrefix, :trailingModifier) = semVerTarget;

  switch (target) {
    case 'major':
      return version.nextMajor();
    case 'minor':
      return version.nextMinor();
    case 'patch':
      return version.nextPatch();

    default:
      {
        final isPrelease = target == 'prerelease';
        final updatedMetadata = _bumpMetadata(
          isPrelease ? version.prerelease : version.buildMetadata,
          indexOrPrefix: indexOrPrefix,
          trailingModifier: trailingModifier,
        ).join('.');

        return isPrelease
            ? version.appendPrerelease(updatedMetadata, keepBuild: false)
            : version.appendBuildInfo(updatedMetadata);
      }
  }
}

/// Dynamically bumps build or prelease metadata provided
List<dynamic> _bumpMetadata(
  List<dynamic> metadata, {
  required dynamic indexOrPrefix,
  required String? trailingModifier,
}) {
  final hasTrailingModifier = trailingModifier != null;

  /// If [indexOrPrefix] is null, then [prefix] is null. All we have to do
  /// is look for the first numeric part of the metadata and bump it.
  ///
  /// Trailing modifier must also be none.
  if (indexOrPrefix == null && !hasTrailingModifier) {
    final (index, int? value) = metadata.indexed.firstWhere(
      (value) => value.$2 is int,
      orElse: () => (-1, null),
    );

    if (index != -1) {
      metadata[index] = value! + 1;
    }
    return metadata;
  }

  final (index, valueAtIndex) = _getPositionInMetadata(metadata, indexOrPrefix);

  final accessorHasIndex = index != -1;
  final hasAccessor = valueAtIndex != null;

  // Exclusively depend on accessor if trailingModifier is absent.
  if (!hasTrailingModifier || trailingModifier.isEmpty) {
    // By default, if [valueAtIndex] is `null`, clear the entire metadata.
    if (!hasAccessor) return metadata..clear();

    // If [index] was `-1`, we add at the end as additional metadata.
    if (!accessorHasIndex) return metadata..add(valueAtIndex);

    // Normally, update the [valueAtIndex] and ignore any trailing metadata.
    return [...metadata.take(index), _updateInPlace(valueAtIndex)];
  }

  final (firstIsPeriod, metaToAdd) = _extractTrailingModInfo(trailingModifier);

  // Take any metadata needed from the current
  final baseMetadata = <dynamic>[
    if (accessorHasIndex) ...metadata.take(index),
  ];

  /// From this point onwards, consider the update rule for the build metadata,
  ///   build{A}{B} such that:
  ///     * `A` is the accessor
  ///     * `B` is the trailing modifier may/may not have metadata info
  ///

  /// If the `B` starts with a period, the rule suggests update without getting
  /// rid of the `A`
  if (firstIsPeriod && accessorHasIndex) {
    switch (trailingModifier) {
      /// build{A}{.}
      ///
      /// - If A is present, update inlined. Bump `int` by 1 while strings are
      ///   rewritten as "A-<int>"
      case '.' when hasAccessor:
        baseMetadata.add(_updateInPlace(valueAtIndex));

      /// build{A}{.}
      ///
      /// - If A is absent, add 1 at the end.
      case '.' when !hasAccessor:
        baseMetadata.add(1);

      /// build{A}{.value(.value)*}
      ///
      /// - If A is present, add all after A
      /// - If A is absent, add at the end of current metadata
      default:
        if (hasAccessor) baseMetadata.add(valueAtIndex);
        baseMetadata.addAll(metaToAdd);
    }
    //
  } else if (accessorHasIndex && hasAccessor && index < metadata.length) {
    /// build{A}{value(.value)*}
    ///
    /// - A is present within the metadata.
    final metaAtHead = metaToAdd.firstOrNull;

    if (metaAtHead != null) {
      /// If equal to A, update in-place. Otherwise swap them. And add any
      /// remaining metadata
      baseMetadata
        ..add(
          valueAtIndex.toString().startsWith(metaAtHead)
              ? _updateInPlace(valueAtIndex)
              : metaAtHead,
        )
        ..addAll(metaToAdd.skip(1));
    }
  } else {
    /// build{A}{value(.value)*}
    ///
    /// - If A is absent, add it.
    if (hasAccessor) baseMetadata.add(valueAtIndex);

    // Add at the end by default.
    baseMetadata.addAll(metaToAdd);
  }

  return _pruneTrailing(baseMetadata);
}

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
  if (indexOrPrefix is String) {
    return indexOrPrefix.isEmpty
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
