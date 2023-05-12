import 'package:magical_version_bump/src/utils/models/magical_data_model.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// This mixin handles all file modification and version updates
mixin ModifyYamlFile {
  /// Modify yaml file
  ///   1. `absoluteChange` - whether user used the modify/change command.
  ///       `true` for change and `false` for modify
  ///   2. `absoluteVersion` - new version provided for the change command
  ///   3. `action` - bump or dump
  ///   4. `targets` - list of SemVer number targets
  ///   5. `yamlData` - data extracted from the file
  ///   6. `logger` - logger for writing to stdout
  Future<ModifiedFileData> modifyFile({
    required bool absoluteChange, // Whether user triggered modify/change
    String? absoluteVersion,
    String? action,
    List<String>? targets,
    required YamlFileData yamlData,
    required Logger logger,
  }) async {
    //
    var versionToSave = '';
    final actionProgress = logger.progress(
      "${absoluteChange ? 'Changing' : 'Modifying'} version",
    );
    var showFinalProgress = true;

    if (!absoluteChange) {
      final versionEntry = await _checkVersion(yamlData.yamlMap, logger);

      versionToSave = await _bumpOrDumpVersion(
        action!,
        targets!,
        versionEntry.value,
      );
    } else {
      final versionIsValid = await _versionIsValid(absoluteVersion);

      if (versionIsValid) {
        versionToSave = absoluteVersion!;
      } else {
        actionProgress.fail('Invalid/missing version');
        showFinalProgress = false;
        versionToSave = await _promptForVersion(logger);
      }
    }

    final updatedFileData = await _editYamlFile(
      versionToSave,
      yamlData.file,
    );

    if (showFinalProgress) {
      actionProgress.complete('Modified version');
    }

    return ModifiedFileData(
      path: yamlData.path,
      modifiedFile: updatedFileData,
    );
  }

  /// Read version number from YAML map. Always returns a
  /// [MapEntry<bool, String>] where:
  ///   1. bool - indicates whether the version was present
  ///   2. String - the version number
  Future<MapEntry<bool, String>> _checkVersion(
    YamlMap yamlMap,
    Logger logger,
  ) async {
    final checkProgress = logger.progress('Checking version number');

    // Check if param is there
    final hasVersion = yamlMap.containsKey('version');

    if (hasVersion) {
      // Get only the first version entry
      final versionEntry = yamlMap.entries.firstWhere(
        (element) => element.key == 'version',
      );

      var version = versionEntry.value as String?;

      final currentIsValid = await _versionIsValid(version);

      if (!currentIsValid) {
        checkProgress.fail('Invalid version number found');

        version = await _promptForVersion(logger);

        return MapEntry(hasVersion, version);
      }

      checkProgress.complete('Validated version number');

      return MapEntry(hasVersion, version!);
    }

    checkProgress.fail('Missing version number');

    final promptedVersion = await _promptForVersion(logger);

    return MapEntry(hasVersion, promptedVersion);
  }

  /// Bump or dump version by 1
  Future<String> _bumpOrDumpVersion(
    String action,
    List<String> versionTargets,
    String version,
  ) async {
    // Get various version values
    // major = first, minor = second, patch = last
    final versions = <String>[...version.split('.')];

    // Add missing values
    if (versions.length <= 2 && versionTargets.contains('minor')) {
      versions.insert(1, '0');
    } else if (versions.length < 3 && (versionTargets.contains('patch'))) {
      //
      versionTargets.contains('build-number')
          ? versions.add('0+0')
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

    final modifiableMap = Map<int, String>.from(versions.asMap());

    // Loop all targets and update specific version numbers
    for (final target in versionTargets) {
      // Check index of target
      final targetIndex = _checkIndex(target);

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

    return modifiableMap.values.join('.');
  }

  /// Update yaml file
  Future<String> _editYamlFile(
    String version,
    String file,
  ) async {
    // Edit yaml map
    final yamlEdit = YamlEditor(file)..update(['version'], version);

    return yamlEdit.toString();
  }

  // Any function below this comment is a sub-method of a main method used by
  // the non-private method.

  /// Check index
  int _checkIndex(String target) {
    return target == 'major'
        ? 0
        : target == 'minor'
            ? 1
            : 2;
  }

  /// Prompt for a version to bump or dump
  Future<String> _promptForVersion(Logger logger) async {
    // Ask user if to use 0.0.0 as base
    String version;

    final useDefault = logger.confirm(
      'Add default version 0.0.0 as base?',
      defaultValue: true,
    );

    // If user chose yes
    if (useDefault) {
      version = '0.0.0';
    } else {
      version = logger.prompt(
        'Enter version number : ',
        defaultValue: '0.0.0',
      );

      var newVersionIsValid = await _versionIsValid(version);

      // Loop and make sure version number is valid
      while (!newVersionIsValid) {
        logger.err('Invalid version number');

        version = logger.prompt(
          'Enter version number : ',
          defaultValue: '0.0.0',
        );

        newVersionIsValid = await _versionIsValid(version);
      }
    }

    bool addBuildNumber;

    // Check if version has build number. Prompt for plus if not
    if (version.contains('+')) {
      addBuildNumber = false;
    } else {
      addBuildNumber = logger.confirm(
        'Do you want to add a build number?',
        defaultValue: true,
      );
    }

    // If user wants to add build number
    if (addBuildNumber) {
      var buildNumber = logger.prompt(
        'Enter build number :',
        defaultValue: 1,
      );

      var tempVersion = '$version+$buildNumber';

      // Check if valid
      var tempIsValid = await _versionIsValid(tempVersion);

      while (!tempIsValid) {
        logger.err('Invalid build number');

        buildNumber = logger.prompt(
          'Enter build number :',
          defaultValue: 1,
        );

        tempVersion = '$version+$buildNumber';

        tempIsValid = await _versionIsValid(tempVersion);
      }

      version = '$version+$buildNumber';
    }

    return version;
  }

  /// Check version validity using SEMVER versioning
  Future<bool> _versionIsValid(String? version) async {
    if (version == null) return false;

    final versionSplit = version.split('.');

    // Max length is 3 for SEMVER
    if (versionSplit.length > 3) return false;

    // Must have at length of 3 if build number is present
    if (versionSplit.length < 3 &&
        versionSplit.any((element) => element.contains('+'))) {
      return false;
    }

    for (final versionNumber in versionSplit) {
      // If version number has build number
      if (versionNumber.contains('+')) {
        final convertedList = versionNumber.split('+').map(int.tryParse);

        if (convertedList.any((element) => element == null)) {
          return false;
        }
      } else {
        final parsedVersionNumber = int.tryParse(versionNumber);

        if (parsedVersionNumber == null) return false;
      }
    }

    return true;
  }
}
