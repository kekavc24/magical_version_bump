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
    // Get build number just incase
    final buildFromVersion = int.tryParse(
      build.isEmpty ? '1' : build.last.toString(),
    );

    var modifiedVersion = '';

    // Get version targets less build-number
    final nonBuildTargets = versionTargets.where(
      (element) => element != 'build-number',
    );

    // Bump version relatively
    if (strategy == ModifyStrategy.relative && nonBuildTargets.isNotEmpty) {
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
    }

    // Just perform an absolute bump
    if (strategy == ModifyStrategy.absolute && nonBuildTargets.isNotEmpty) {
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

    if (modifiedVersion.isEmpty) {
      modifiedVersion = "$major.$minor.$patch-${preRelease.join('.')}";

    }

    if (versionTargets.contains('build-number')) {
      final buildToModify = buildFromVersion ?? 1;

      final buildNumber =
          bumpType == BumpType.up ? buildToModify + 1 : buildToModify - 1;

      modifiedVersion += '+${buildNumber < 0 ? 0 : buildNumber}';
    } else if (buildFromVersion != null) {
      modifiedVersion += '+$buildFromVersion';
    }

    return modifiedVersion;
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
}
