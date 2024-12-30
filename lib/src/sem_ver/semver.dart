import 'dart:math';

import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/utils/extensions.dart';
import 'package:magical_version_bump/src/utils/utils.dart';
import 'package:meta/meta.dart';
import 'package:petitparser/petitparser.dart';

part 'semver_utils.dart';

/// Represents a class that implements
/// [Semantic Versioning](https://semver.org/). Its implementation is similar
/// to that [pub_semver](https://pub.dev/packages/pub_semver) with some tweaks.
@immutable
final class SemVer implements Comparable<SemVer> {
  SemVer._(
    this.canCompareBuild,
    this._major,
    this._minor,
    this._patch,
    List<dynamic>? prerelease,
    List<dynamic>? buildMetadata,
  ) {
    _prerelease.addAll(prerelease ?? []);
    _buildMetadata.addAll(buildMetadata ?? []);
  }

  /// Parses a string and creates a valid [SemVer] object.
  ///
  /// `[canCompareBuild]` - if `true`, the object includes the `build metadata`
  /// when comparing versions. This is how
  /// [pub_semver](https://pub.dev/packages/pub_semver) behaves. If `false`,
  /// then the `build metadata` is excluded when comparing [SemVer] versions.
  /// This is what [Semantic Versioning](https://semver.org/) recommends.
  ///
  /// `[NOTE]:` Both [SemVer] versions need [canCompareBuild] to be `true` for
  /// `build metadata` to be used.
  SemVer.parse(String version, {required this.canCompareBuild}) {
    //
    // Intentionally verbose instead of using regex.
    //
    final length = version.length;

    // Look for first index of `-` i.e start of prerelease
    var prereleaseStartIndex = version.indexOf('-');

    // Look for first index of `+` i.e start of build number
    final buildInfoStartIndex = version.indexOf('+', prereleaseStartIndex + 1);

    /// Fallback to the string's entire length if no build info is present.
    /// Otherwise, start of build info indicates end of prelease (exclusive)
    var nonBuildInfoEnd =
        buildInfoStartIndex == -1 ? length : buildInfoStartIndex;

    // Same logic as above applies to version core end with prerelease.
    final versionCoreEnd =
        prereleaseStartIndex == -1 ? nonBuildInfoEnd : prereleaseStartIndex;

    _parseVersionCore(version.substring(0, versionCoreEnd));

    /// Move start position forward for pre-release. Skip `-`
    prereleaseStartIndex += 1;
    if (prereleaseStartIndex != 0 && prereleaseStartIndex != length) {
      final prereleaseSub = version.substring(
        prereleaseStartIndex,
        nonBuildInfoEnd,
      );

      splitMetadata(
        prereleaseSub,
        callback: _prerelease.addAll,
        exception: semverException(
          'Expected a valid pre-release version',
          prereleaseSub,
        ),
      );
    }

    /// Move start position forward for build. Skip `+`
    nonBuildInfoEnd++;
    if (nonBuildInfoEnd < length) {
      final buildSub = version.substring(nonBuildInfoEnd);

      splitMetadata(
        buildSub,
        callback: _buildMetadata.addAll,
        exception: semverException('Expected valid build metadata', buildSub),
      );
    }
  }

  /// Creates [SemVer] object.
  SemVer.rawUnchecked(
    int major,
    int minor,
    int patch, {
    bool canCompareBuild = true,
    List<dynamic>? prerelease,
    List<dynamic>? buildMetadata,
  }) : this._(canCompareBuild, major, minor, patch, prerelease, buildMetadata);

  /// Indicates whether [buildMetadata] should be included when comparing
  /// [SemVer] versions.
  final bool canCompareBuild;

  late final int _major;
  late final int _minor;
  late final int _patch;

  final _prerelease = <dynamic>[];
  final _buildMetadata = <dynamic>[];

  /// The major version number: `10` in `10.9.8`
  ///
  /// Resets [minor] & [patch] to `0` when incremented. Any [pre-release] info
  /// is discarded.
  int get major => _major;

  /// The minor version: `9` in `10.9.8`
  ///
  /// Resets [patch] to `0` when incremented. Any [pre-release] info is
  /// discarded.
  int get minor => _minor;

  /// The patch version: `8` in `10.9.8`
  ///
  /// Discards only the [pre-release] info.
  int get patch => _patch;

  /// Returns the core version portion, that is, `major.minor.patch`.
  ///
  /// Example: core version in `1.0.0-pre+10` is `1.0.0`
  String get versionCore => '$_major.$_minor.$patch';

  /// The pre-release version identifier: `alpha` in `10.9.8-alpha`.
  ///
  /// Allows multiple identifiers  that are dot-separated and are split when
  /// parsed. Must be preceded by a `-`. Digits and alphabetical letters are
  /// allowed (a-z, A-Z, "-").
  ///
  /// Example: `alpha.beta.12` in `10.9.8-alpha.beta.12`.
  List<dynamic> get prerelease => [..._prerelease];

  /// Indicates whether this is a pre-release version.
  bool get isPrerelease => _prerelease.isNotEmpty;

  /// The build metadata of a version: `1098` in `10.9.8+1098`.
  ///
  /// Allows multiple identifiers  that are dot-separated and are split when
  /// parsed. Must be preceded by a `+`. Digits and alphabetical letters are
  /// allowed (a-z, A-Z, "-").
  ///
  /// Example: `build.1098-pre` in `10.9.8+build.1098-pre`.
  List<dynamic> get buildMetadata => [..._buildMetadata];

  /// Indicates whether a version has any build metadata
  bool get hasBuildInfo => _buildMetadata.isNotEmpty;

  String get metadata {
    var metadata = '';
    if (isPrerelease) metadata += '-${_prerelease.join('.')}';
    if (hasBuildInfo) metadata += '+${_buildMetadata.join('.')}';
    return metadata;
  }

  /// Parses the core version identifier in a valid
  /// [SemVer](https://semver.org/) version string.
  ///
  /// Expects: `<major>.<minor>.<patch>` . All numeric.
  ///
  /// Throws an [ArgumentError] if a non-numeric identifier is found.
  void _parseVersionCore(String? version) {
    const invalidCore = 'Expected <major>.<minor>.<patch>';
    if (version == null) {
      throw semverException(invalidCore, 'null');
    }

    final core = version.split('.');
    if (core.length != 3) {
      throw semverException(invalidCore, version);
    }

    String identifier(int index) => switch (index) {
          0 => 'major',
          1 => 'minor',
          _ => 'patch',
        };

    final versions = core.mapIndexed((index, target) {
      final parsed = int.tryParse(target);
      if (parsed == null) {
        throw semverException(
          'Expected a numeric <${identifier(index)}> identifier ',
          target,
        );
      }
      return parsed;
    });

    _major = versions.elementAt(0);
    _minor = versions.elementAt(1);
    _patch = versions.elementAt(2);
  }

  bool operator <(SemVer other) => compareTo(other) < 0;
  bool operator <=(SemVer other) => compareTo(other) <= 0;
  bool operator >(SemVer other) => compareTo(other) > 0;
  bool operator >=(SemVer other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is SemVer &&
      runtimeType == other.runtimeType &&
      compareTo(other) == 0;

  @override
  int get hashCode =>
      Object.hashAll([_major, _minor, _patch, _prerelease, _buildMetadata]);

  @override
  int compareTo(SemVer other) {
    /// Order of magnitude
    ///
    /// major > minor > patch > pre-release
    if (_major != other.major) return _major.compareTo(other.major);
    if (_minor != other.minor) return _minor.compareTo(other.minor);
    if (_patch != other.patch) return _patch.compareTo(other.patch);

    /// Availability of pre-release means it has a lower precedence
    if (isPrerelease && !other.isPrerelease) return -1;
    if (!isPrerelease && other.isPrerelease) return 1;

    final comparison = compareMetadata(_prerelease, other._prerelease);

    if (comparison != 0) return comparison;

    return canCompareBuild && other.canCompareBuild
        ? compareMetadata(_buildMetadata, other._buildMetadata)
        : 0;
  }

  @override
  String toString() => versionCore + metadata;
}
