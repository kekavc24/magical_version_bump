part of 'arg_normalizer.dart';

final class ReplacerArgumentsNormalizer extends ArgumentsNormalizer {
  ReplacerArgumentsNormalizer({
    required super.argResults,
    required this.isRename,
  });

  final bool isRename;

  late ParsedValues _replacementCandidates;
  late ListOfParsedValues _targetCandidates;

  @override
  ({bool isValid, InvalidReason? reason}) customValidate() {
    _replacementCandidates = argResults!.replacementCandidates;

    if (_replacementCandidates.isEmpty) {
      return (
        isValid: false,
        reason: const InvalidReason(
          'Missing replacements',
          'You need to provide at one replacement',
        ),
      );
    }

    // Get targets based on Replacer Type
    _targetCandidates =
        isRename ? argResults!.targetKeys : argResults!.targetValues;

    if (_targetCandidates.isEmpty) {
      return (
        isValid: false,
        reason: InvalidReason(
          "Missing ${isRename ? 'keys' : 'values'}",
          "You need to provide at least one ${isRename ? 'key' : 'value'}",
        ),
      );
    }
    return super.customValidate(); // Defaults to success
  }

  @override
  ({Aggregator aggregator, List<ReplacementTargets> targets}) prepArgs() {
    // Create modifiable list
    final replacementCandidates = [..._replacementCandidates];

    ///
    /// The [ArgParser] parses in sequence, so order of arguments remains.
    ///
    /// We match each target to replacement based on the corresponding index
    /// in replacement.
    ///
    /// If length is less, last replacement value will act as the replacement
    /// for others
    final linked = <String, List<String>>{};

    for (final candidate in _targetCandidates) {
      // Get replacement. If empty, use last key in linked map
      final replacement = replacementCandidates.firstOrNull ?? linked.keys.last;

      linked.update(
        replacement,
        (current) => [...current, ...candidate],
        ifAbsent: () => candidate,
      );

      // Remove candidate from list
      if (replacementCandidates.isNotEmpty) replacementCandidates.removeAt(0);
    }

    return (
      aggregator: argResults!.getAggregator(),
      targets: linked.entries
          .map((e) => (areKeys: isRename, replacement: e.key, targets: e.value))
          .toList(),
    );
  }
}
