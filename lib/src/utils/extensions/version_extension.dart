import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:pub_semver/pub_semver.dart';

extension VersionExtension on Version {
  /// Bump up version
  ({bool buildHadIssues, String version}) modifyVersion({
    required List<String> versionTargets,
    required ModifyStrategy strategy,
  }) {
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

      final target = nonBuildTargets.first;

      modifiedVersion = nextRelativeVersion(target).toString();

      //
    } else if (strategy == ModifyStrategy.absolute && bumpNonBuild) {
      // Just perform an absolute bump
      final mappedVersion = getVersionAsMap();

      // Loop all targets and bump by one
      for (final target in nonBuildTargets) {
        final version = mappedVersion[target] ?? 0;

        final moddedVersion = version + 1;

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
      if (isPreRelease) {
        modifiedVersion += "-${preRelease.join('.')}";
      }
    }

    // Check if build is just one integer. This makes it "bump-able"
    final buildIsBumpable = buildIsNumber();

    // Check whether we should bump the build.
    final shouldBumpBuild =
        (buildIsBumpable && versionTargets.contains('build-number')) ||
            (build.isEmpty && versionTargets.contains('build-number'));

    // If build is bumpable, bump it
    if (shouldBumpBuild) {
      // Get build number just incase
      final buildFromVersion = buildIsBumpable
          ? build.first as int
          : build.isEmpty && shouldBumpBuild
              ? 0
              : null;

      final buildNumber = (buildFromVersion ?? 0) + 1;

      modifiedVersion += '+$buildNumber';
    } else {
      // Just add build number as is.
      var buildNumber = build.isEmpty
          ? ''
          : build.fold(
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

  /// Set prerelease and build-number
  String setPreAndBuild({
    bool keepPre = false,
    bool keepBuild = false,
    String? updatedPre,
    String? updatedBuild,
  }) {
    return Version(
      major,
      minor,
      patch,
      pre: updatedPre ??
          (keepPre && preRelease.isNotEmpty ? preRelease.join('.') : null),
      build: updatedBuild ??
          (keepBuild && build.isNotEmpty ? build.join('.') : null),
    ).toString();
  }

  /// Get value of next relative version
  Version nextRelativeVersion(String target) {
    return switch (target) {
      'minor' => nextMinor,
      'patch' => nextPatch,
      _ => nextMajor
    };
  }

  /// Get versions as map
  Map<String, int> getVersionAsMap() {
    return {'major': major, 'minor': minor, 'patch': patch};
  }

  /// Check if build is valid.
  /// Must have one value & should be an integer
  bool buildIsNumber() {
    return build.length == 1 && build.first is int;
  }
}
