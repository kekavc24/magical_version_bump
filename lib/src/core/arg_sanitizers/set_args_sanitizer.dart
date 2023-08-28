part of 'arg_sanitizer.dart';

final class SetArgumentSanitizer extends ArgumentSanitizer {
  SetArgumentSanitizer({required super.argResults});

  /// Prep arguments and values as Map<String, String>
  @override
  NodesAndValues prepArgs() {
    final preppedArgs = <String, String>{};

    // Get all values for default nodes supported
    final supportedNodeValues = nodesSupported.fold(
      <String, String>{},
      (previousValue, element) {
        final nodeValue = argResults![element] as String?;

        if (nodeValue == null) return previousValue;

        previousValue.update(
          element,
          (value) => nodeValue,
          ifAbsent: () => nodeValue,
        );

        return previousValue;
      },
    );

    if (supportedNodeValues.isNotEmpty) {
      preppedArgs.addAll(supportedNodeValues);
    }

    // Add any specified "new/existing" nodes
    final parsedNodes = argResults!['key'] as List<String>;
    final parsedNodeValues = argResults!['value'] as List<String>;

    // Since ArgParser parses in sequence, we ASSUME that is the order in which
    // the user wanted them. Also, The length must m-a[RGH]-tch. Haha!
    if (parsedNodes.isNotEmpty &&
        parsedNodeValues.isNotEmpty &&
        (parsedNodes.length == parsedNodeValues.length)) {
      for (var i = 0; i < parsedNodes.length; i++) {
        preppedArgs.update(
          parsedNodes[i],
          (value) => parsedNodeValues[i],
          ifAbsent: () => parsedNodeValues[i],
        );
      }
    }

    return preppedArgs;
  }

  /// Validate and return prepped args
  ({
    bool isValid,
    InvalidReason? reason,
    NodesAndValues? nodesAndValues,
  }) customValidate({required bool didSetVersion}) {
    // Check if arguments results are empty
    final checkedArgs = validateArgs();

    if (!checkedArgs.isValid && !didSetVersion) {
      return (
        isValid: checkedArgs.isValid,
        reason: checkedArgs.reason,
        nodesAndValues: null,
      );
    }

    // Prep args
    final preppedArgs = prepArgs();

    return (
      isValid: preppedArgs.isNotEmpty || didSetVersion,
      reason: preppedArgs.isNotEmpty || didSetVersion
          ? null
          : const InvalidReason('Missing arguments', 'No arguments found'),
      nodesAndValues: preppedArgs.isNotEmpty ? preppedArgs : null,
    );
  }
}
