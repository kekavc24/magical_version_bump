part of 'helpers.dart';

/// Type of sanitizer
enum SanitizerType {
  bump,
  setter,
}

/// Set up desired sanitizer type on demand
ArgumentsChecker setUpSanitizer(
  SanitizerType type, {
  required ArgParser argParser,
  required List<String> args,
}) {
  return switch (type) {
    SanitizerType.setter => SetArgumentsChecker(
        argResults: argParser.parse(args),
      ),
    _ => BumpArgumentsChecker(argResults: argParser.parse(args))
  };
}
