part of 'helpers.dart';

Matcher throwsCustomException(String message) {
  return throwsA(
    isA<MagicalException>().having((e) => e.message, 'message', message),
  );
}
