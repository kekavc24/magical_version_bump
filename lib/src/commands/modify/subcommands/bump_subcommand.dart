part of 'modify_subcommands.dart';

/// This command only modifies one node, bumps the version.
class BumpSubcommand extends ModifySubCommand {
  BumpSubcommand({required super.logger}) {
    argParser
      ..addOption(
        'target',
        mandatory: true,
        abbr: 't',
        help: 'A valid semVer version',
      )
      ..addFlag(
        'preset',
        abbr: 'p',
        help:
            '''Preset any version, prerelease and build info before bumping the version''',
        negatable: false,
      )
      ..addOption(
        'strategy',
        help: 'Whether to do a relative/absolute versioning.',
        allowed: ['relative', 'absolute'],
        defaultsTo: 'relative',
      );
  }

  @override
  String get name => 'bump';

  @override
  String get description => 'A subcommand that bumps a valid semVer version';
}
