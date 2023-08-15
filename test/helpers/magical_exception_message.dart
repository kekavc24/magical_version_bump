import 'package:magical_version_bump/src/core/exceptions/command_exceptions.dart';
import 'package:test/test.dart';

Matcher throwsViolation(String message) {
  return throwsA(
    isA<MagicalException>().having((e) => e.violation, 'violation', message),
  );
}
