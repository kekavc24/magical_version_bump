import 'dart:async';

import 'package:magical_version_bump/src/commands/runnable_command.dart';
import 'package:magical_version_bump/src/sem_ver/semver.dart';
import 'package:magical_version_bump/src/utils/extensions.dart';
import 'package:magical_version_bump/src/utils/input_iterator.dart';
import 'package:yaml/yaml.dart';

/// Core version targets
final _versionSetTargets = {'major', 'minor', 'patch'};

/// Metadata targets
final _metadataSetTargets = {'prerelease', 'build'};

/// Targets that be triggered by a `preset`
final _presetTargets = {
  'all',
  'version',
  'metadata',
  ..._versionSetTargets,
  ..._metadataSetTargets,
};

/// Targets to set/preset
final _setMarkers = {
  'M', // major
  'm', // minor
  'p', // patch
  'pre', // prerelease
  'b', // build
};

/// Targets to bump. Allows all to be targeted simultaneously
typedef BumpTargets = ({
  String? versionTarget,
  String? prereleaseTarget,
  String? buildTarget,
});

/// {@template semver_sub_command}
/// A command that bumps `semantic version`s
/// {@endtemplate}
final class SemverSubcommand extends RunnableCommand {
  /// {@macro semver_sub_command}
  SemverSubcommand() {
    argParser
      ..addFlag(
        'breaking',
        help: 'Indicates version to be bumped to the next BREAKING version',
      )
      ..addFlag(
        'keep-pre',
        aliases: ['kp'],
        help:
            'Indicates whether to retain the prerelease metadata on a version',
      )
      ..addFlag(
        'keep-build',
        aliases: ['kb'],
        help: 'Indicates whether to retain the build metadata on a version',
      )
      ..addFlag(
        'prefer-inline-output',
        defaultsTo: true,
        help:
            'Indicates whether multiple version bumped should be printed in one'
            ' line',
      )
      ..addOption(
        'input',
        abbr: 'i',
        help: 'Indicates how the tool should read input',
        allowed: ['file', 'version'],
        defaultsTo: 'version',
        allowedHelp: {
          'file':
              'Reads versions from a json/yaml file. Pass in a version param if'
                  ' not "version"',
          'version': 'Reads versions from the command line if any are present',
        },
      )
      ..addMultiOption(
        'set',
        abbr: 's',
        help:
            'Values to be overriden before/after bumping a version. See README'
            ' for further help.',
      )
      ..addOption(
        'target',
        abbr: 't',
        allowed: _versionSetTargets,
        help: 'Core version targets',
        allowedHelp: {
          'major': 'Major version identifier',
          'minor': 'Minor version identifier',
          'patch': 'Patch version identifier',
        },
      )
      ..addOption(
        'prereleaseTarget',
        aliases: ['preTarget', 'pT'],
        help: 'Strategy to bump the prerelease metadata',
      )
      ..addOption(
        'buildTarget',
        aliases: ['bT'],
        help: 'Strategy to bump the build metadata',
      )
      ..addOption(
        'versionParam',
        aliases: ['vp'],
        defaultsTo: 'version',
        help: 'Indicates key in json/yaml that points to version',
      )
      ..addMultiOption(
        'preset',
        abbr: 'p',
        help: 'Presets any targets provided to "set" option',
        allowed: _presetTargets,
        allowedHelp: {
          'all': 'Presets all identifiers provided',
          'version': 'Presets only the major, minor and patch identifiers',
          'metadata': 'Presets only the prerelease and build metadata',
          'major': 'Presets only the major version identifier',
          'minor': 'Presets only the minor version identifier',
          'patch': 'Presets only the patch version identifier',
          'prerelease': 'Presets only the prerelease metadata',
          'build': 'Presets only the build metadata',
        },
      );
  }

  @override
  String get description => 'A subcommand that bumps a valid semVer version';

  @override
  String get name => 'semver';

  @override
  Future<void> runnable() async {
    final parsedResults = argResults!;

    final restArgs = parsedResults.rest;

    //if (restArgs.isEmpty) return;

    final presetTargets = degenarilizeTargets(parsedResults.values('preset'));

    final setValues = extractSetValues(parsedResults.values('set'));

    final bumpTargets = (
      versionTarget: parsedResults.nullableValue('target'),
      prereleaseTarget: addMetaPrefix(
        'prerelease',
        parsedResults.nullableValue('prereleaseTarget'),
      ),
      buildTarget: addMetaPrefix(
        'build',
        parsedResults.nullableValue('buildTarget'),
      ),
    );

    final keepPre = parsedResults.booleanValue('keep-pre');
    final keepBuild = parsedResults.booleanValue('keep-build');
    final isBreaking = parsedResults.booleanValue('breaking');

    final versions = parsedResults.value('input') == 'file'
        ? await runBumpForFiles(
            restArgs,
            versionParam: parsedResults.value('versionParam'),
            presetTargets: presetTargets,
            setValues: setValues,
            isBreaking: isBreaking,
            bumpTargets: bumpTargets,
            keepPre: keepPre,
            keepBuild: keepBuild,
          )
        : restArgs.map(
            (version) => runBumpVersion(
              version,
              presetTargets: presetTargets,
              setValues: setValues,
              isBreaking: isBreaking,
              bumpTargets: bumpTargets,
              keepPre: keepPre,
              keepBuild: keepBuild,
            ),
          );

    final output = versions.join(
      parsedResults.booleanValue('prefer-inline-output') ? ' ' : '\n',
    );

    print(output);
  }
}

/// Removes abigous references to targets to be preset.
///
/// See [_presetTargets].
Iterable<String> degenarilizeTargets(Iterable<String> targets) {
  if (targets.isEmpty) return [];

  final degeneralized = targets.toSet();

  if (degeneralized.contains('all')) {
    return [..._versionSetTargets, ..._metadataSetTargets];
  }

  return {
    ...degeneralized,
    if (degeneralized.contains('version')) ..._versionSetTargets,
    if (degeneralized.contains('metadata')) ..._metadataSetTargets,
  };
}

String? addMetaPrefix(String prefix, String? modifier) {
  if (modifier != null) {
    return '$prefix${modifier.trim()}';
  }

  return null;
}

/// Extracts values that are to preset/set before/after bumping a version
/// respectively.
Map<String, dynamic> extractSetValues(Iterable<String> values) {
  if (values.isEmpty) return {};

  FormatException exception(String message, String value) {
    return FormatException(message, value);
  }

  return values.fold({}, (map, current) {
    final split = current.split('=').map((value) => value.trim());

    // Must at least equate it to something. Even nothing is okay.
    if (split.length != 2) {
      throw exception('Only 2 values are required', current);
    }

    var key = split.first;
    dynamic value = split.last;

    if (!_setMarkers.contains(key)) {
      throw exception('Unknown version marker', key);
    }

    if ((value as String).isEmpty) {
      value = switch (key) {
        'M' || 'm' || 'p' => 0, // version markers
        _ => '',
      };
    } else {
      // Version markers must be valid
      switch (key) {
        case 'M':
        case 'm':
        case 'p':
          {
            value = int.tryParse(value);

            if (value == null) {
              throw exception('Expected an integer for key "$key"', current);
            }
          }

        default:
          //
          final identifier = key == 'pre' ? 'prerelease' : 'build';

          // For posterity, catch erroneous metadata provided!
          splitMetadata(
            value,
            callback: (data) => data,
            exception: exception('Expected valid $identifier', value),
          );
      }
    }

    key = switch (key) {
      'M' => 'major',
      'm' => 'minor',
      'p' => 'patch',
      'pre' => 'prerelease',
      _ => 'build',
    };

    map[key] = value;
    return map;
  });
}

/// Bumps a semantic version
String runBumpVersion(
  String version, {
  required Iterable<String> presetTargets,
  required Map<String, dynamic> setValues,
  required bool isBreaking,
  required BumpTargets bumpTargets,
  required bool keepPre,
  required bool keepBuild,
}) {
  final (:versionTarget, :prereleaseTarget, :buildTarget) = bumpTargets;
  final oldVersion = SemVer.parse(version, canCompareBuild: true);

  SemVer nestedSetter(SemVer version, String target, dynamic value) {
    return switch (target) {
      'major' => version.setVersion(major: value as int?),
      'minor' => version.setVersion(minor: value as int?),
      'patch' => version.setVersion(patch: value as int?),
      'prerelease' => version.appendPrerelease(
          value as String? ?? '',
          keepBuild: true,
        ),
      _ when target.isNotEmpty => version.appendBuildInfo(
          value as String? ?? '',
        ),
      _ => oldVersion
    };
  }

  var versionToUpdate = oldVersion;

  // Preset all targets
  if (presetTargets.isNotEmpty) {
    for (final preset in presetTargets) {
      final value = setValues[preset];
      versionToUpdate = nestedSetter(versionToUpdate, preset, value);
      setValues.remove(preset);
    }
  }

  var bumpedVersion = versionToUpdate.versionCore;

  // Bump version core
  bumpedVersion = switch (isBreaking) {
    // Prefer breaking release always
    true => versionToUpdate.nextBreaking.versionCore,

    // Fallback to version target
    false when versionTarget != null => bumpSemVer(
        versionToUpdate,
        (target: versionTarget, indexOrPrefix: null, trailingModifier: null),
      ).versionCore,

    // Leave untouched
    _ => bumpedVersion
  };

  // Bump prerelease. Prefer to always bump it.
  final bumpedPre = switch (prereleaseTarget) {
    null when keepPre => versionToUpdate.prerelease,
    null => <dynamic>[],
    _ => bumpSemVerWithString(versionToUpdate, prereleaseTarget)
        .prerelease
  };

  if (bumpedPre.isNotEmpty) bumpedVersion += '-${bumpedPre.join('.')}';

  // Bump build. Prefer to always bump it.
  final bumpedBuild = switch (buildTarget) {
    null when keepBuild => versionToUpdate.buildMetadata,
    null => <dynamic>[],
    _ => bumpSemVerWithString(versionToUpdate, buildTarget).buildMetadata
  };

  if (bumpedBuild.isNotEmpty) bumpedVersion += '+${bumpedBuild.join('.')}';

  // Set values not meant to be preset
  if (setValues.isNotEmpty) {
    var temp = SemVer.parse(bumpedVersion, canCompareBuild: true);

    for (final MapEntry(:key, :value) in setValues.entries) {
      temp = nestedSetter(temp, key, value);
    }

    bumpedVersion = temp.toString();
  }

  return bumpedVersion;
}

/// Bumps the version specified in a json/yaml file
Future<List<String>> runBumpForFiles(
  List<String> paths, {
  required String versionParam,
  required Iterable<String> presetTargets,
  required Map<String, dynamic> setValues,
  required bool isBreaking,
  required BumpTargets bumpTargets,
  required bool keepPre,
  required bool keepBuild,
}) async {
  final queue = FileQueue<YamlMap>(
    files: paths,
    transform: (file) async => loadYaml(await file.readAsString()) as YamlMap,
  );

  final versionsBumped = <String>[];

  while (queue.hasNext) {
    final (:path, :transformed) = await queue.next;

    var version = transformed[versionParam] as String?;

    if (version == null) {
      throw Exception('No version found for $path');
    }

    version = runBumpVersion(
      version,
      presetTargets: presetTargets,
      setValues: setValues,
      isBreaking: isBreaking,
      bumpTargets: bumpTargets,
      keepPre: keepPre,
      keepBuild: keepBuild,
    );

    versionsBumped.add(version);
    transformed[versionParam] = version;
    await queue.saveFile(path, transformed, prettifyJson: true);
  }

  return versionsBumped;
}
