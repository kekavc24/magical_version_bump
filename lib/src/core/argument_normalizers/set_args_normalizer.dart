part of 'arg_normalizer.dart';

final class SetArgumentsNormalizer extends ArgumentsNormalizer {
  SetArgumentsNormalizer({required super.argResults});

  /// Prep dictionaries
  @override
  (List<Dictionary> dictionaries, VersionModifiers modifiers) prepArgs() {
    // Always fetch dicts to add first. Dicts that overwrite
    final dictInputs = <String>[...argResults!.parsedValues('dictionary')];

    // Get offset, before we add dicts to append
    final offset = dictInputs.isEmpty ? -1 : dictInputs.length;

    dictInputs.addAll(argResults!.parsedValues('add'));

    final dictBuilders = DictionaryParser().parseAll(dictInputs);

    final mappedBuilders = dictBuilders.foldIndexed(
      <String, List<DictBuilder>>{},
      (index, previous, element) {
        final dictKey = index < offset ? 'add' : 'append';
        previous.update(
          dictKey,
          (value) => [...value, element],
          ifAbsent: () => [element],
        );
        return previous;
      },
    );

    final dictionaries = <Dictionary>[
      ...mappedBuilders['add']?.map(
            (e) => (
              data: e.data,
              rootKeys: e.rootKeys,
              updateMode: UpdateMode.overwrite
            ),
          ) ??
          [],
      ...mappedBuilders['append']?.map(
            (e) => (
              data: e.data,
              rootKeys: e.rootKeys,
              updateMode: UpdateMode.append
            ),
          ) ??
          [],
    ];

    return (dictionaries, VersionModifiers.fromArgResults(argResults!));
  }
}
