import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/map_extensions.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// This mixin modifies a yaml/json node to desired option
mixin ModifyYaml {
  /// Update yaml file
  Future<String> updateYamlFile(
    FileOutput fileOutput, {
    required Dictionary dictionary,
  }) async {
    // Setup editor
    final editor = YamlEditor(fileOutput.file);

    // Get keys to use in update
    final rootKeys = [...dictionary.rootKeys];

    /// To ensure efficiency, if:
    ///
    /// 1. Only one root key is present
    /// 2. Root is being overwritten
    ///
    /// Update and return updated file
    if (rootKeys.length == 1 && dictionary.updateMode != UpdateMode.append) {
      editor.update([rootKeys.first], dictionary.data);

      return editor.toString();
    }

    /// Convert file to map
    final fileAsDynamicMap = {...fileOutput.fileAsMap};

    /// When more than 1 key is provided, we need to guarantee that:
    ///
    ///   1. Update to yaml file never fails due to a missing root key. If
    ///      absent, create the necessary missing nodes.
    ///   2. Update a node storing a string to list, if append is true
    ///   3. Never append a list to an existing map and vice versa
    ///
    /// For this we need,
    ///   `depth` - how far deep the node is in yaml map, which is the number
    ///   of keys before the node we want to read
    ///
    final depth = rootKeys.length - 1;

    /// Remove the target key, which is the last element.
    ///
    /// * `removeAt` ensures we never remove duplicate keys which are nested!
    /// * `depth` indicates index of last element too
    /// * `targetKey` is the last element removed
    final targetKey = rootKeys.removeAt(depth);

    // Recursively update the file (map representation of it)
    final updatedMap = fileAsDynamicMap.recursivelyUpdate(
      dictionary.data,
      target: targetKey,
      path: rootKeys,
      updateMode: dictionary.updateMode,
      keyAndReplacement: {},
      valueToReplace: null,
    );

    /// Get the key that appears first in the file.
    ///
    /// The `anchorKey` will be first root key or the `targetKey` we want to
    /// update of no root keys are available
    final anchorKey = rootKeys.isEmpty ? targetKey : rootKeys.first;

    final dataToSave = updatedMap[anchorKey];

    // Update as a whole instead of being granular
    editor.update([anchorKey], dataToSave);

    return editor.toString();
  }
}
