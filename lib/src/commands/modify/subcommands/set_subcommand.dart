part of 'modify_subcommands.dart';

/// This command modifies several nodes of yaml file
class SetSubcommand extends ModifySubCommand {
  SetSubcommand({required super.logger})
      : _logger = logger,
        _hander = HandleSetCommand(logger: logger) {
    argParser
      ..addMultiOption(
        'dictionary',
        help: 'Specify a key to add/overwrite and value(s) separated with "="',
        aliases: ['dict'],
        splitCommas: false,
      )
      ..addMultiOption(
        'add',
        help: 'Specify a key to append value(s) to separated with "="',
        splitCommas: false,
      );
  }

  @override
  String get name => 'set';

  @override
  String get description =>
      'A subcommand that adds, appends a value or overwrites a node in a yaml/json file';

  final Logger _logger;
  final HandleSetCommand _hander;

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
