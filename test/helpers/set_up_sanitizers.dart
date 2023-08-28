part of 'helpers.dart';

/// Type of sanitizer
enum SanitizerType {
  bump,
  setter,
}

/// Set up desired sanitizer type on demand
ArgumentSanitizer setUpSanitizer(
  SanitizerType type, {
  required ArgParser argParser,
  required List<String> args,
}) {
  return switch (type) {
    SanitizerType.setter => SetArgumentSanitizer(
        argResults: argParser.parse(args),
      ),
    _ => BumpArgumentSanitizer(argResults: argParser.parse(args))
  };
}
