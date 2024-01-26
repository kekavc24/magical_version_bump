part of 'helpers.dart';

Matcher throwsViolation(String message) {
  return throwsA(
    isA<MagicalException>().having((e) => e.message, 'message', message),
  );
}
