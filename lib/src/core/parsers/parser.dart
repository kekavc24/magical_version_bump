import 'package:magical_version_bump/src/utils/exceptions/exceptions.dart';

part 'tokenizer.dart';

typedef ParseException = MagicalException;

abstract base class Parser<OutputT> {
  /// Parses and returns the result from this input
  ///
  /// Throws a `ParseException` if unable to parse the input
  OutputT parse(String input, int inputIndex, {bool reset = true});

  /// Parses and returns the results for each input provided
  List<OutputT> parseAll(List<String> inputs) {
    final outputs = <OutputT>[];
    for (final (inputIndex, input) in inputs.indexed) {
      outputs.add(parse(input, inputIndex));
    }
    return outputs;
  }
}
