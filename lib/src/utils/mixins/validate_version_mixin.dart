import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

/// This mixin validates and prompts for correct version to be set if invalid
mixin ValidateVersion {
  /// Check if version is valid and return the correct version.
  ///
  /// * `isModify` - check whether the modify command triggered this function.
  /// `Modify` command uses the version in yaml wherease `Change` command passes
  /// in a preferred version to change to.
  ///
  /// * `yamlMap` - only passed in by `Modify` command
  /// * `version` - only passed in by `Change` command
  Future<String> validateVersion({
    required Logger logger,
    required bool isModify,
    YamlMap? yamlMap,
    String? version,
  }) async {
    final checkProgress = logger.progress('Checking version number');

    var validVersion = '';

    // Modify command uses version in yaml.
    if (isModify) {
      if (yamlMap == null) {
        throw MagicalException(violation: 'YAML Map cannot be null');
      }

      if (yamlMap.containsKey('version')) {
        // Get only the first version entry
        final versionEntry = yamlMap.entries.firstWhere(
          (element) => element.key == 'version',
        );

        validVersion = versionEntry.value as String? ?? '';
      }
    } else {
      validVersion = version ?? '';
    }

    if (validVersion.isEmpty) {
      checkProgress.fail('Missing version number');

      return _promptForVersion(logger);
    }

    final isValid = await _versionIsValid(validVersion);

    if (isValid) {
      checkProgress.complete('Validated version number');

      return validVersion;
    }

    checkProgress.fail('Invalid version number');

    return _promptForVersion(logger);
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
