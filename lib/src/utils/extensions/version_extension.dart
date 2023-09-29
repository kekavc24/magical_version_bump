import 'package:pub_semver/pub_semver.dart';

extension VersionExtension on Version {
  /// Set prerelease and build-number
  String setPreAndBuild({
    String? updatedPre,
    String? updatedBuild,
  }) {
    return Version(
      major,
      minor,
      patch,
      pre: updatedPre,
      build: updatedBuild,
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
