part of 'helpers.dart';

Matcher throwsCustomException(String message) {
  return throwsA(
    isA<MagicalException>().having((e) => e.message, 'message', message),
  );
}

String createDictParserMessage(
  String input,
  String message, {
  int position = 0,
}) {
  return '''[0: $position]: $input. \n${lightRed.wrap(message)}''';
}
