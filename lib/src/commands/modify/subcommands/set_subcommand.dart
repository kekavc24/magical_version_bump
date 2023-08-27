part of 'modify_subcommands.dart';

/// This command modifies several nodes of yaml file
class SetSubcommand extends ModifySubCommand {
  SetSubcommand({required super.logger})
      : _logger = logger,
        _hander = HandleSetCommand(logger: logger) {
    argParser
      ..addOption(
        'name',
        help: 'Change the name in pubspec.yaml',
      )
      ..addOption(
        'description',
        help: 'Change the description of your project in pubspec.yaml',
        aliases: ['desc'],
      )
      ..addOption(
        'homepage',
        help: 'Change the homepage url in pubspec.yaml',
      )
      ..addOption(
        'repository',
        help: '''Change the repository url for project in pubspec.yaml''',
      )
      ..addOption(
        'issue_tracker',
        help: '''Change the url pointing to an issue tracker in pubspec.yaml''',
      )
      ..addOption(
        'documentation',
        help:
            '''Change the url pointing to your project's documentation in pubspec.yaml''',
      )
      ..addMultiOption(
        'key',
        help: 'A key to overwrite/append in yaml file',
      )
      ..addMultiOption(
        'value',
        help: 'A value corresponding to a key specified',
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
