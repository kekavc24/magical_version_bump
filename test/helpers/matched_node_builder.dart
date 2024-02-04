part of 'helpers.dart';

/// Creates a single [MatchedNodeData] based on a provided predicate
MatchedNodeData buildMatchedNode(
  List<NodeData> nodes, {
  required bool Function(NodeData) predicate,
  List<String>? matchedKeys,
  String? matchedValue,
  Map<String, String>? matchedPairs,
}) =>
    MatchedNodeData.fromFinder(
      nodeData: nodes.firstWhere(predicate),
      matchedKeys: matchedKeys ?? [],
      matchedValue: matchedValue ?? '',
      matchedPairs: matchedPairs ?? {},
    );
