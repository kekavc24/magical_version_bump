import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:pub_semver/pub_semver.dart';
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
  Future<({bool buildBumpFailed, String version})> dynamicBump(
    String version, {
    required String action,
    required List<String> versionTargets,
    ModifyStrategy strategy = ModifyStrategy.relative,
  }) async {
    return Version.parse(version).modifyVersion(
      action.bumpType,
      versionTargets: versionTargets,
      strategy: strategy,
    );
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
