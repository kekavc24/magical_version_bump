import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// This mixin validates and prompts for correct version to be set if invalid
mixin ValidateVersion {
  /// Check if version is valid and return the correct version.
  ///
  /// * `useYamlVersion` - check whether to use version in yaml.
  /// `Modify` command uses the version in yaml wherease `Change` command passes
  /// in a preferred version to change to.
  ///
  /// * `yamlMap` - only passed in by `Modify` command
  /// * `version` - only passed in by `Change` command
  Future<String> validateVersion({
    required Logger logger,
    required bool useYamlVersion,
    YamlMap? yamlMap,
    String? version,
  }) async {
    final checkProgress = logger.progress('Checking version number');

    var validVersion = '';

    // Modify command uses version in yaml.
    if (useYamlVersion) {
      if (yamlMap == null) {
        throw MagicalException(violation: 'YAML Map cannot be null');
      }

      if (yamlMap.containsKey('version')) {
        validVersion = yamlMap['version']?.toString() ?? '';
      }
    } else {
      validVersion = version ?? '';
    }

    if (validVersion.isEmpty) {
      checkProgress.fail('Missing version number');

      return _promptForVersion(logger);
    }

    final isValid = _versionIsValid(validVersion);

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
    Version? version;
    var versionNumber = '';
    String? prerelease;
    String? build;

    var promptForVersion = true;

    while (promptForVersion) {
      final useDefault = logger.confirm(
        'Add default version 0.0.0 as base?',
        defaultValue: true,
      );

      // If user chose yes
      if (useDefault) {
        versionNumber = '0.0.0';
      } else {
        versionNumber = logger.prompt(
          'Enter version number : ',
          defaultValue: '0.0.0',
        );
      }

      // Ask user if this is a prerelease version. Just in case
      final isPrelease = logger.confirm('Mark this as a prerelease version?');

      if (isPrelease) {
        prerelease = logger.prompt(
          'Enter prerelease info : ',
          defaultValue: 'alpha',
        );
      }

      // Ask if user wants a build number
      final addBuildNumber = logger.confirm(
        'Do you want to add build info (typically a build number)?',
        defaultValue: true,
      );

      // If user wants to add build number
      if (addBuildNumber) {
        build = logger.prompt(
          'Enter build number : ',
          defaultValue: 1,
        );
      }

      final versionNumbers = versionNumber.split('.');

      // Check if any value is null
      final hasNullVersions = versionNumbers.any(
        (element) => int.tryParse(element) == null,
      );

      if (hasNullVersions || versionNumbers.length != 3) {
        logger.err('Invalid version number!');
        continue;
      }

      // Parse version numbers
      final parsedVersions = versionNumbers.map(int.parse).toList();

      version = Version(
        parsedVersions.first,
        parsedVersions[1],
        parsedVersions.last,
        pre: prerelease,
        build: build,
      );

      promptForVersion = !_versionIsValid(version.toString());
    }

    return version.toString();
  }

  /// Check version validity using SEMVER versioning
  bool _versionIsValid(
    String? version,
  ) {
    try {
      Version.parse(version ?? '');
    } catch (e) {
      return false;
    }

    return true;
  }
}
