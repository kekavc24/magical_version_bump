import 'package:yaml_edit/yaml_edit.dart';

/// This mixin modifies a yaml node to desired option
mixin ModifyYaml {
  /// Bump or dump version by 1. Used by the `Modify` command.
  ///
  /// With absolute,
  /// each version number will be bumped independently.
  ///
  /// 1.1.1 -> bump major version -> 2.1.1
  ///
  /// With relative,
  /// each version is modified relative to its position. This the default
  /// behaviour i.e
  ///
  /// 1.1.1 -> bump major version -> 2.0.0
  Future<String> dynamicBump(
    String action,
    List<String> versionTargets,
    String version, {
    required bool absoluteVersioning,
  }) async {
    final versions = getVersions(version, versionTargets);

    final modifiableMap = Map<int, String>.from(versions.asMap());

    // Loop all targets and update specific version numbers
    for (final target in versionTargets) {
      // Check index of target
      final targetIndex = checkIndex(target);

      // Get version to modify
      final versionToMod = versions[targetIndex];

      // This means patch number has build number. We get value instead from
      // stored map
      if (versionToMod.contains('+')) {
        final patchTargets =
            modifiableMap.values.elementAt(targetIndex).split('+');

        // Patch targets to modify. Build number is last and patch is first
        final subVersionToMod =
            target == 'patch' ? patchTargets.first : patchTargets.last;

        var modifiedVersion = action == 'bump' || action == 'b'
            ? int.parse(subVersionToMod) + 1
            : int.parse(subVersionToMod) - 1;

        modifiedVersion = modifiedVersion < 0 ? 0 : modifiedVersion;

        modifiableMap.update(
          targetIndex,
          (value) => target == 'patch'
              ? '$modifiedVersion+${patchTargets.last}'
              : '${patchTargets.first}+$modifiedVersion',
        );
      } else {
        var modifiedVersion = action == 'bump' || action == 'b'
            ? int.parse(versionToMod) + 1
            : int.parse(versionToMod) - 1;

        modifiedVersion = modifiedVersion < 0 ? 0 : modifiedVersion;

        modifiableMap.update(
          targetIndex,
          (value) => modifiedVersion.toString(),
        );
      }
    }

    if (absoluteVersioning) {
      return modifiableMap.values.join('.');
    }

    /// Get the target that was passed in first
    final relativeTarget = versionTargets.first;

    var relativeVersion = '';

    if (relativeTarget == 'major') {
      relativeVersion = '${modifiableMap[0]}.0.0';
    } else if (relativeTarget == 'minor') {
      relativeVersion = '${modifiableMap[0]}.${modifiableMap[1]}.0';
    } else {
      relativeVersion =
          '${modifiableMap[0]}.${modifiableMap[1]}.${modifiableMap[2]}';
    }

    final buildNumber =
        modifiableMap.values.last.contains('+') && relativeTarget != 'patch'
            ? '+${modifiableMap[2]!.split('+').last}'
            : '';

    return relativeVersion += buildNumber;
  }

  /// Check index
  int checkIndex(String target) {
    return target == 'major'
        ? 0
        : target == 'minor'
            ? 1
            : 2;
  }

  /// Get versions
  List<String> getVersions(String version, List<String> versionTargets) {
    // Get various version values
    // major = first, minor = second, patch = last
    final versions = <String>[...version.split('.')];

    // Add missing values
    if (versions.length <= 2 && versionTargets.contains('minor')) {
      versions.insert(1, '0');
    } else if (versions.length < 3 && (versionTargets.contains('patch'))) {
      //
      versionTargets.contains('build-number')
          ? versions.add('0+1')
          : versions.add('0');
    } else if (versions.length == 3 &&
        versionTargets.contains('build-number')) {
      // Check if last digit has build number
      final hasBuildNum = versions.last.contains('+');

      if (!hasBuildNum) {
        final patchVersion = versions.last;

        versions
          ..remove(patchVersion)
          ..insert(2, '$patchVersion+1');
      }
    }

    return versions;
  }

  /// Edit yaml file
  Future<String> editYamlFile(
    String file,
    String yamlNode,
    String yamlValue,
  ) async {
    // Edit yaml map
    final yamlEdit = YamlEditor(file)..update([yamlNode], yamlValue);

    return yamlEdit.toString();
  }
}
