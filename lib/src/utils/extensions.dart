import 'dart:math';

import 'package:args/args.dart';
import 'package:magical_version_bump/src/sem_ver/semver.dart';
import 'package:magical_version_bump/src/utils/utils.dart';

extension ArgExtension on ArgResults {
  /// Get nullable value
  String? nullableValue(String argument) => this[argument] as String?;

  /// Get a non-nullable value
  String value(String argument) => nullableValue(argument) ?? '';

  /// Get a boolean value
  bool booleanValue(String argument) => this[argument] as bool;

  /// Get a list of values in multi-option
  List<String> values(String argument) => this[argument] as List<String>;
}

extension SemverUtils on SemVer {
  /// Updates the version.
  ///
  /// If [version] is provided, it is parsed and used as the version.
  SemVer setVersion({
    String? version,
    int? major,
    int? minor,
    int? patch,
  }) {
    final updated = version == null
        ? this
        : SemVer.parse(version, canCompareBuild: canCompareBuild);

    return SemVer.rawUnchecked(
      major ?? updated.major,
      minor ?? updated.minor,
      patch ?? updated.patch,
      prerelease: updated.prerelease,
      buildMetadata: updated.buildMetadata,
    );
  }

  /// Appends [prerelease] metadata to a version.
  ///
  /// If [keepBuild] is true, existing build info is preserved.
  SemVer appendPrerelease(String prerelease, {required bool keepBuild}) {
    final pre = <dynamic>[];

    if (prerelease.isNotEmpty) {
      splitMetadata(
        prerelease,
        callback: pre.addAll,
        exception: semverException(
          'Expected valid prerelease metadata',
          prerelease,
        ),
      );
    }

    return SemVer.rawUnchecked(
      major,
      minor,
      patch,
      prerelease: pre,
      buildMetadata: keepBuild ? buildMetadata : [],
    );
  }

  /// Appends [buildInfo] to a version.
  SemVer appendBuildInfo(String buildInfo) {
    final build = <dynamic>[];

    if (buildInfo.isNotEmpty) {
      splitMetadata(
        buildInfo,
        callback: build.addAll,
        exception: semverException('Expected valid build metadata', buildInfo),
      );
    }

    return SemVer.rawUnchecked(
      major,
      minor,
      patch,
      prerelease: prerelease,
      buildMetadata: build,
    );
  }

  /// Bumps the major version.
  ///
  /// Any prerelease and build metadata is discarded by default unless [keepPre]
  /// and [keepBuild] are `true`.
  SemVer nextMajor({bool keepPre = false, bool keepBuild = false}) {
    return SemVer.rawUnchecked(
      isPrerelease ? major : major + 1,
      0,
      0,
      prerelease: keepPre ? prerelease : [],
      buildMetadata: keepBuild ? buildMetadata : [],
    );
  }

  /// Bumps the minor version.
  ///
  /// Any prerelease and build metadata is discarded by default unless [keepPre]
  /// and [keepBuild] are `true`.
  SemVer nextMinor({bool keepPre = false, bool keepBuild = false}) {
    return SemVer.rawUnchecked(
      major,
      isPrerelease ? minor : minor + 1,
      0,
      prerelease: keepPre ? prerelease : [],
      buildMetadata: keepBuild ? buildMetadata : [],
    );
  }

  /// Bumps the patch version.
  ///
  /// Any prerelease and build metadata is discarded by default unless [keepPre]
  /// and [keepBuild] are `true`.
  SemVer nextPatch({bool keepPre = false, bool keepBuild = false}) {
    return SemVer.rawUnchecked(
      major,
      minor,
      isPrerelease ? patch : patch + 1,
      prerelease: keepPre ? prerelease : [],
      buildMetadata: keepBuild ? buildMetadata : [],
    );
  }

  /// Returns the next breaking version. Typically, a [nextMajor] version
  /// only if it's not `0`.
  SemVer get nextBreaking => major == 0 ? nextMinor() : nextMajor();
}

extension StringUtil on String {
  /// Returns the safe substring ensuring the [start] and [end] are not outside
  /// the range.
  ///
  /// If [start] is outside the range, an empty string is returned.
  String safeSubstring(int start, [int? end]) {
    if (start >= length) return '';
    return substring(start, end != null ? min(length, end) : end);
  }
}
