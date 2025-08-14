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
  /// Wr give preference to the `period (.)` modifier.
  switch (accessorHasIndex) {
    /// If the `B` starts with a period, the rule suggests we try updating
    /// without getting rid of the `A`
    case _ when firstIsPeriod:
      _leadingPeriodMod(
        baseMetadata,
        accessorHasIndex: accessorHasIndex,
        hasAccessor: hasAccessor,
        accessor: valueAtIndex,
        trailingModifier: trailingModifier,
        oldMetadata: metadata,
        metadataToAdd: metaToAdd,
      );

    /// `A` was present. As an valid index or within the existing metadata
    /// itself. Also, the index must be within the metadata range
    case true when hasAccessor && index < metadata.length:
      _replaceOrUpdateInPlace(
        baseMetadata,
        accessor: valueAtIndex,
        metadataToAdd: metaToAdd,
      );

    default:
      _addAtEnd(
        baseMetadata,
        hasAccessor: hasAccessor,
        accessor: valueAtIndex,
        metadataToAdd: metaToAdd,
      );
  }

  return _pruneTrailing(baseMetadata);
}
