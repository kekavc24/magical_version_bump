part of 'modify_subcommands.dart';

/// This command only modifies one node, bumps the version.
class BumpSubcommand extends ModifySubCommand {
  BumpSubcommand({required super.logger})
      : _logger = logger,
        _hander = HandleBumpCommand(logger: logger) {
    argParser
      ..addMultiOption(
        'targets',
        abbr: 't',
        help: 'A valid semVer version',
        allowed: ['major', 'minor', 'patch', 'build-number'],
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

  final Logger _logger;
  final HandleBumpCommand _hander;

  @override
  Future<int> run() async {
    try {
      await _hander.handleCommand(argResults);
    } on MagicalException catch (e) {
      _logger.err(e.toString());

      return ExitCode.usage.code;
    } on PathNotFoundException catch (e) {
      _logger.err(e.message);

      return ExitCode.osFile.code;
    } catch (e) {
      _logger.err(e.toString());

      return ExitCode.software.code;
    }
    return ExitCode.success.code;
  }
}
