import 'package:args/command_runner.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/handlers/command_handlers.dart';
import 'package:mason_logger/mason_logger.dart';

/// This command overwrites/writes the version in the pubspec.yaml
class ChangeNodesCommand extends Command<int> {
  ChangeNodesCommand({
    required Logger logger,
  })  : _logger = logger,
        _handler = HandleChangeCommand(logger: logger) {
    argParser
      ..addFlag(
        'with-path',
        help:
            '''Tells CLI to request file path instead of checking current directory''',
        negatable: false,
      )
      ..addMultiOption(
        'name',
        help: '''Change the name in pubspec.yaml''',
        valueHelp: 'Hello Word',
      )
      ..addOption(
        'description',
        help: '''Change the description of your project in pubspec.yaml''',
        valueHelp: 'This project says hello to the world',
      )
      ..addOption(
        'yaml-version',
        help: '''Option to completely change the version in pubspec.yaml''',
        valueHelp: '1.1.0',
      )
      ..addOption(
        'homepage',
        help: '''Change the homepage url in pubspec.yaml''',
        valueHelp: 'https://url.to.homepage',
      )
      ..addOption(
        'repository',
        help: '''Change the repository url for project in pubspec.yaml''',
        valueHelp: 'https://url.to.repository-on-github',
      )
      ..addOption(
        'issue_tracker',
        help: '''Change the url pointing to an issue tracker in pubspec.yaml''',
        valueHelp: 'https://url.to.issue-tracker',
      )
      ..addOption(
        'documentation',
        help:
            '''Change the url pointing to your project's documentation in pubspec.yaml''',
        valueHelp: 'https://url.to.documentation',
      );
  }

  @override
  String get description =>
      'A command that adds/overwrites the version specified in the pubspec.yaml file';

  @override
  String get name => 'change';

  final Logger _logger;
  final HandleChangeCommand _handler;

  @override
  Future<int> run() async {
    try {
      await _handler.handleCommand(argResults!.arguments);

      // Read file
    } on MagicalException catch (e) {
      _logger.err(e.toString());

      return ExitCode.usage.code;
    } on Exception catch (e) {
      _logger.err(e.toString());

      return ExitCode.software.code;
    }
    return ExitCode.success.code;
  }
}
