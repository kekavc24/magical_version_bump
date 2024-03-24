import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../../../helpers/helpers.dart';

void main() {
  final map = <String, dynamic>{
    'normalKey': 'value',
    'keyWithMap': {'keyInMap': 'value'},
    'keyWithList': [
      {'keyInList': 'value'},
    ],
  };

  late YamlMap yamlMap;

  /// Generated one time nodes for ease of access
  late List<NodeData> nodes;

  /// Has no notion of the underlying data. Only mutates what is presented
  /// to it
  late KeySwapper keySwapper;

  /// Value is the same, only predicate changes
  MatchedNodeData getMatch({
    required bool Function(NodeData) predicate,
    required List<String> matchedKeys,
  }) {
    return buildMatchedNode(
      nodes,
      predicate: predicate,
      matchedKeys: matchedKeys,
    );
  }

  setUp(() {
    yamlMap = YamlMap.wrap(map);
    nodes = MagicalIndexer.forDartMap(map).index().toList();
    keySwapper = KeySwapper(
      {
        'replacedKeyAtRoot': ['normalKey'],
        'replacedKeyInAnotherMap': ['keyInMap'],
        'replacedKeyInList': ['keyInList'],
      },
    );
  });

  group('swaps key', () {
    test('at root level', () {
      final match = getMatch(
        predicate: (node) => node.precedingKeys.isEmpty,
        matchedKeys: const ['normalKey'],
      );

      final output = keySwapper.replace(yamlMap, matchedNodeData: match);

      final expectedMap = {
        'replacedKeyAtRoot': 'value',
        'keyWithMap': {'keyInMap': 'value'},
        'keyWithList': [
          {'keyInList': 'value'},
        ],
      };

      expect(output.mapping, equals({'normalKey': 'replacedKeyAtRoot'}));
      expect(output.updatedMap, equals(expectedMap));
    });

    test('nested in another map', () {
      final match = getMatch(
        predicate: (node) => node.precedingKeys.isNotEmpty,
        matchedKeys: const ['keyInMap'],
      );

      final output = keySwapper.replace(yamlMap, matchedNodeData: match);

      final expectedMap = {
        'normalKey': 'value',
        'keyWithMap': {'replacedKeyInAnotherMap': 'value'},
        'keyWithList': [
          {'keyInList': 'value'},
        ],
      };

      expect(output.mapping, equals({'keyInMap': 'replacedKeyInAnotherMap'}));
      expect(output.updatedMap, equals(expectedMap));
    });

    test('nested in a list', () {
      final match = getMatch(
        predicate: (node) => node.isNestedInList(),
        matchedKeys: const ['keyInList'],
      );

      final output = keySwapper.replace(yamlMap, matchedNodeData: match);

      final expectedMap = {
        'normalKey': 'value',
        'keyWithMap': {'keyInMap': 'value'},
        'keyWithList': [
          {'replacedKeyInList': 'value'},
        ],
      };

      expect(output.mapping, equals({'keyInList': 'replacedKeyInList'}));
      expect(output.updatedMap, equals(expectedMap));
    });
  });
}
