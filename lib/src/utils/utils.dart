import 'dart:math';

const _baseError = 'Invalid SemVer version string.';

/// Creates an [FormatException] thrown when parsing a version.
FormatException semverException(String error, String versionPortion) {
  return FormatException('$_baseError $error', versionPortion);
}

/// Highlights an error within a string.
///
/// [offendingCharPattern] - represents the character that is not required in
/// the string.
///
/// [allowedCount] - represents the number of times the [offendingCharPattern]
/// can exist within the string.
///
/// [applyIfMissing] - indicates whether to highlight the errors if
/// `allowedCount > 0` and no such character was found.
///
/// Returns the string "as is" if no error was found. Otherwise, applies
/// carets such that:
///
/// ```yaml
/// # If the offending char is the "-"
///
///   MyStringWithError-
///   ^^^^^^^^^^^^^^^^^^
/// ```
String highlightError(
  String string, {
  required String offendingCharPattern,
  required int allowedCount,
  required bool applyIfMissing,
}) {
  final strLen = string.length;
  const padding = '    ';

  const notInRange = -1;

  final buffer = StringBuffer('$padding$string\n$padding');

  final pattern = RegExp(offendingCharPattern);

  // Get first (non)-offending index of the char.
  final firstIndex = string.indexOf(pattern);
  var indexInString = firstIndex;

  // We have to at-least search ahead once
  var extraCheckCount = allowedCount - 1;
  extraCheckCount = max(0, extraCheckCount) == 0 ? 1 : extraCheckCount;

  // Exit once we find the first offending instance or none.
  while (extraCheckCount > 0 && indexInString != -1) {
    indexInString = string.indexOf(pattern, indexInString + 1);
    --extraCheckCount;
  }

  // Fallback to first index if not outside the range
  indexInString = switch (indexInString) {
    notInRange when firstIndex != notInRange => firstIndex,
    _ => indexInString
  };

  // If not found, no need to highlight the error with caret :)
  if (indexInString == notInRange && !applyIfMissing) {
    return string;
  }

  /// If no extra character is found but was expected or not. Apply carets upto
  /// the end of string
  if (extraCheckCount > 0 || indexInString == firstIndex && allowedCount > 1) {
    indexInString = strLen;
  }

  applyCarets(buffer, min(indexInString + 1, strLen));
  return buffer.toString();
}

void applyCarets(StringBuffer buffer, int count) {
  const caret = '^';
  var caretCount = count;

  while (caretCount > 0) {
    buffer.write(caret);
    --caretCount;
  }
}
