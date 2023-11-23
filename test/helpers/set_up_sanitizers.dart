part of 'helpers.dart';

/// Type of sanitizer
enum ArgCheckerType {
  bump,
  setter,
}

/// Default arg parser for sanitizer
ArgParser setUpArgParser() {
  return ArgParser()
    ..addOption(
      'set-version',
      aliases: ['ver'],
    )
    ..addOption(
      'set-prerelease',
      aliases: ['pre'],
    )
    ..addOption(
      'set-build',
      aliases: ['build'],
    )
    ..addFlag(
      'keep-pre',
      negatable: false,
    )
    ..addFlag(
      'keep-build',
      negatable: false,
    )
    ..addMultiOption(
      'dictionary',
      aliases: ['dict'],
      splitCommas: false,
    )
    ..addMultiOption(
      'add',
      splitCommas: false,
    )
    ..addMultiOption(
      'targets',
      allowed: ['major', 'minor', 'patch', 'build-number'],
    )
    ..addFlag(
      'preset',
      negatable: false,
    )
    ..addOption(
      'strategy',
      allowed: ['relative', 'absolute'],
    );
}

/// Set up desired sanitizer type on demand
ArgumentsNormalizer setUpSanitizer(
  ArgCheckerType type, {
  required ArgParser argParser,
  required List<String> args,
}) {
  return switch (type) {
    ArgCheckerType.setter => SetArgumentsNormalizer(
        argResults: argParser.parse(args),
      ),
    _ => BumpArgumentsNormalizer(argResults: argParser.parse(args))
  };
}
