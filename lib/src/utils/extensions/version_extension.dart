import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:pub_semver/pub_semver.dart';

extension VersionExtension on Version {
  /// Bump up version
  String modifyVersion(
    BumpType bumpType, {
    required List<String> versionTargets,
    ModifyStrategy strategy = ModifyStrategy.relative,
  }) {
    // Check if build is just one number. This makes it "bump-able"
    final canBumpBuild = buildIsNumber();

    // Get build number just incase
    final buildFromVersion = canBumpBuild ? build.first as int : null;

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
          violation: 'Expected only one target for this versioning strategy',
        );
      }

      if (bumpType == BumpType.down) {
        throw MagicalException(
          violation:
              'This versioning strategy does not allow bumping down versions',
        );
      }

      final target = nonBuildTargets.first;

      modifiedVersion = nextRelativeVersion(target).toString();

      //
    } else if (strategy == ModifyStrategy.absolute && bumpNonBuild) {
      // Just perform an absolute bump
      final mappedVersion = getVersionAsMap();

      // Loop all targets and bump by one
      for (final target in nonBuildTargets) {
        final version = mappedVersion[target] ?? 0;

        final moddedVersion =
            bumpType == BumpType.up ? version + 1 : version - 1;

        mappedVersion.update(
          target,
          (value) => moddedVersion < 0 ? 0 : moddedVersion,
        );
      }

      modifiedVersion = mappedVersion.values.map((e) => e.toString()).join('.');

      // If pre-release, append it only when we are not relatively bumping it
      if (isPreRelease) {
        modifiedVersion += "-${preRelease.join('.')}";
      }
    }

    // An empty modified version means user targeted the build number
    if (modifiedVersion.isEmpty) {
      modifiedVersion = '$major.$minor.$patch';

      //
      if (isPreRelease && strategy == ModifyStrategy.absolute) {
        modifiedVersion += "-${preRelease.join('.')}";
      }
    }

    // If build is bumpable, bump it
    if (versionTargets.contains('build-number')) {
      final buildToModify = buildFromVersion ?? 1;

      final buildNumber =
          bumpType == BumpType.up ? buildToModify + 1 : buildToModify - 1;

      modifiedVersion += '+${buildNumber < 0 ? 0 : buildNumber}';

      //
    } else {
      // Just add build number as is.
      var buildNumber = build.isEmpty
          ? ''
          : build.fold(
              '+',
              (previousValue, element) => '$previousValue.$element',
            );

      // If build number was added, remove first "." added
      if (build.isNotEmpty) {
        buildNumber = buildNumber.replaceFirst('.', '');
      }

      modifiedVersion += buildNumber;
    }

    return modifiedVersion;
  }

  /// Set prerelease and build-number
  String setPreAndBuild({
    bool keepPre = false,
    bool keepBuild = false,
    String? updatedPre,
    String? updatedBuild,
  }) {
    if ((keepPre && preRelease.isEmpty) || (keepBuild && build.isEmpty)) {
      throw MagicalException(
        violation:
            '''You cannot change to new version and keep old prerelease and build info''',
      );
    }

    return Version(
      major,
      minor,
      patch,
      pre: updatedPre ?? (keepPre ? preRelease.join('.') : null),
      build: updatedBuild ?? (keepBuild ? build.join('.') : null),
    ).toString();
  }

  /// Get value of next relative version
  Version nextRelativeVersion(String target) {
    switch (target) {
      case 'minor':
        return nextMinor;

      case 'patch':
        return nextPatch;

      default:
        return nextMajor;
    }
  }

  /// Get versions as map
  Map<String, int> getVersionAsMap() {
    return {'major': major, 'minor': minor, 'patch': patch};
  }

  /// Check if build is valid
  /// Check if the build numbers are valid build. Must have one value &
  /// should be an integer
  bool buildIsNumber() {
    return build.length == 1 && build.first is int;
  }
}
