import 'package:magical_version_bump/src/utils/data/version_modifiers.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/magical_exception.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:pub_semver/pub_semver.dart';

Version _parseVersion(String version) => Version.parse(version);

/// Add any presets based on the `presetType` and return version
String addPresets(
  String versionFromFile, {
  required VersionModifiers modifiers,
}) {
  // If no preset was set, return version from file as is.
  if (modifiers.presetType == PresetType.none) return versionFromFile;

  /// If only the version will be preset, return the version passed in from
  /// `set-version` stored in the version modifier class.
  ///
  /// Must not be `NULL`. Also make sure no old prerelease/build needs to be
  /// retained
  if (modifiers.presetType == PresetType.version &&
      !modifiers.keepBuild &&
      !modifiers.keepPre) {
    return modifiers.version ?? '';
  }

  /// `Preset.all` is inclusive i.e may include:
  ///   * Only the version
  ///   * Only the prerelease/build info
  ///   * All mentioned above

  // Attempt to parse old version
  Version? oldVersion;

  if (versionFromFile.isNotEmpty) {
    oldVersion = _parseVersion(versionFromFile);
  }

  /// Version from file or Version from `set-version` can be null. Never both
  if (oldVersion == null && modifiers.version == null) {
    throw MagicalException(
      message: 'At least one valid version is required.',
    );
  }

  /// Old version can never be null if we are retaining prerelease & build
  /// info
  if (oldVersion == null && (modifiers.keepBuild || modifiers.keepPre)) {
    throw MagicalException(
      message: 'Old version cannot be empty or null',
    );
  }

  /// As mentioned above both can never be null. Give version from
  /// `set-version` has a higher precedence and only fallback to
  /// old version (version from file) if version from modifiers is null.
  ///
  /// Why?
  ///
  /// Because `set-prerelease` or `set-build` in `preset` may be used but not
  /// `set-version`
  ///
  final version = _parseVersion(
    modifiers.version ?? versionFromFile,
  ).setPreAndBuild(
    updatedPre: modifiers.keepPre
        ? (oldVersion!.preRelease.isNotEmpty
            ? oldVersion.preRelease.join('.')
            : null)
        : modifiers.prerelease,
    updatedBuild: modifiers.keepBuild
        ? (oldVersion!.build.isNotEmpty ? oldVersion.build.join('.') : null)
        : modifiers.build,
  );

  return version;
}

/// Bump version by 1. Used by the `Bump` subcommand.
///
/// With `absolute`, each version number will be bumped independently.
///
/// 1.1.1 -> bump major version -> 2.1.1
///
/// With `relative`, each version is modified relative to its position which
/// is the `DEFAULT` behaviour i.e
///
/// 1.1.1 -> bump major version -> 2.0.0
({bool buildHadIssues, String version}) bumpVersion(
  String version, {
  required List<String> versionTargets,
  required ModifyStrategy strategy,
}) {
  final currentVersion = _parseVersion(version);
  var modifiedVersion = '';

  // Get version targets less build-number
  final nonBuildTargets = versionTargets.where(
    (element) => element != 'build-number',
  );

  // Whether we can bump non-build targets
  final bumpNonBuild = nonBuildTargets.isNotEmpty;

  // Bump version relatively
  if (strategy == ModifyStrategy.relative && bumpNonBuild) {
    if (nonBuildTargets.length > 1) {
      throw MagicalException(
        message: 'Expected only one target for this versioning strategy',
      );
    }

    final target = nonBuildTargets.first;

    modifiedVersion = currentVersion.nextRelativeVersion(target).toString();

    //
  } else if (strategy == ModifyStrategy.absolute && bumpNonBuild) {
    // Just perform an absolute bump
    final mappedVersion = currentVersion.getVersionAsMap();

    // Loop all targets and bump by one
    for (final target in nonBuildTargets) {
      final targetVersion = mappedVersion[target] ?? 0;

      final moddedVersion = targetVersion + 1;

      mappedVersion.update(
        target,
        (value) => moddedVersion,
      );
    }

    modifiedVersion = mappedVersion.values.map((e) => e.toString()).join('.');

    // If pre-release, append it only when we are not relatively bumping it
    if (currentVersion.isPreRelease) {
      modifiedVersion += "-${currentVersion.preRelease.join('.')}";
    }
  }

  // An empty modified version means user targeted the build number
  if (modifiedVersion.isEmpty) {
    modifiedVersion =
        '''${currentVersion.major}.${currentVersion.minor}.${currentVersion.patch}''';

    if (currentVersion.isPreRelease) {
      modifiedVersion += "-${currentVersion.preRelease.join('.')}";
    }
  }

  // Check if build is just one integer. This makes it "bump-able"
  final buildIsBumpable = currentVersion.buildIsNumber();

  // Check whether we should bump the build.
  final shouldBumpBuild = (buildIsBumpable &&
          versionTargets.contains('build-number')) ||
      (currentVersion.build.isEmpty && versionTargets.contains('build-number'));

  // If build is bumpable, bump it
  if (shouldBumpBuild) {
    // Get build number just incase
    final buildFromVersion = currentVersion.build.firstOrNull as int? ?? 0;

    final buildNumber = buildFromVersion + 1;

    modifiedVersion += '+$buildNumber';
  } else {
    // Just add build number as is.
    var buildNumber = currentVersion.build.isEmpty
        ? ''
        : currentVersion.build.fold(
            '+',
            (previousValue, element) => '$previousValue.$element',
          );

    // If build number was added, remove first "." added
    if (buildNumber.isNotEmpty) {
      buildNumber = buildNumber.replaceFirst('.', '');
    }

    modifiedVersion += buildNumber;
  }

  // Check if build was bumped on user's request.
  //
  // Fails if build ended up being "un-bumpable" but user wanted it bumped!
  final didFail = !buildIsBumpable && versionTargets.contains('build-number');

  return (buildHadIssues: didFail, version: modifiedVersion);
}

/// Add any dangling `set-prerelease` or `set-build` info if `preset` was
/// false or only `set-version` was used
String appendPreAndBuild(
  String version, {
  required VersionModifiers modifiers,
}) {
  // Check if preset was used
  final wasPreset = modifiers.presetType == PresetType.all;

  // Check if any info is available to set
  final canAddInfo = modifiers.prerelease != null || modifiers.build != null;

  // Will always return current version if preset was true before checking
  // if any info is available to append
  if (wasPreset || !canAddInfo) {
    return version;
  }

  final versionToSave = _parseVersion(version);

  return versionToSave.setPreAndBuild(
    updatedPre: modifiers.prerelease ??
        (modifiers.keepPre && versionToSave.preRelease.isNotEmpty
            ? versionToSave.preRelease.join('.')
            : null),
    updatedBuild: modifiers.build ??
        (modifiers.keepBuild && versionToSave.build.isNotEmpty
            ? versionToSave.build.join('.')
            : null),
  );
}
