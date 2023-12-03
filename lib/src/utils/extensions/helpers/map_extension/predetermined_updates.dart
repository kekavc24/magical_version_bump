part of '../../map_extensions.dart';

///
/// Updates a "known" list. This denotes a list indexed by `MagicalIndexer`
/// to its root value
///
List<dynamic> _updateIndexedList({
  required bool isTerminal,
  required bool isKey,
  required List<dynamic> list,
  required List<int> indices,
  required dynamic update,
  Key? target,
  List<Key>? path,
  KeyAndReplacement? keyAndReplacement,
  Value? value,
}) {
  // Modifiable list
  final modifiableList = [...list];
  final modifiableIndices = [...indices];

  // We exit once only one index is remaining
  if (modifiableIndices.length == 1) {
    // If at the end and just the value
    if (isTerminal && !isKey) {
      modifiableList[indices.first] = update;
    } else {
      // Get map to recurse
      final recursible = modifiableList[indices.first] as Map<dynamic, dynamic>;

      final updatedMap = isTerminal
          ? {...recursible}._updateIndexedTerminal(
              update,
              target: target!,
              keyAndReplacement: keyAndReplacement!,
              value: value,
            )
          : {...recursible}.updateIndexedMap(
              update,
              target: target!,
              path: path!,
              keyAndReplacement: keyAndReplacement!,
              value: value,
            );

      // Recurse it
      modifiableList[indices.first] = updatedMap;
    }

    return modifiableList;
  }

  // Remove the first index
  final currentIndex = modifiableIndices.removeAt(0);
  
  // Update index recursively
  modifiableList[currentIndex] = _updateIndexedList(
    isTerminal: isTerminal,
    isKey: isKey,
    list: modifiableList[currentIndex] as List,
    indices: modifiableIndices,
    update: update,
    target: target,
    path: path,
    keyAndReplacement: keyAndReplacement,
    value: value,
  );

  return modifiableList;
}
