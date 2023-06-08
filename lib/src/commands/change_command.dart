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
      ..addFlag(
        'keep-pre',
        help:
            '''Explicitly indicates that the tool should keep any existing prerelease version found''',
        negatable: false,
      )
      ..addFlag(
        'keep-build',
        help:
            '''Explicitly indicates that the tool should keep any existing build metadata found''',
        negatable: false,
      )
      ..addOption(
        'set-path',
        help: '''Tell CLI where to check for a pubspec.yaml file''',
      )
      ..addOption(
        'set-prerelease',
        help:
            '''Change the prerelease version in the version specified in your pubspec.yaml file''',
      )
      ..addOption(
        'set-build',
        help:
            '''Change build metadata appended to the version in your pubspec.yaml file''',
      )
      ..addOption(
        'set-version',
        help: '''Option to completely change the version in pubspec.yaml''',
      )
      ..addOption(
        'name',
        help: '''Change the name in pubspec.yaml''',
      )
      ..addOption(
        'description',
        help: '''Change the description of your project in pubspec.yaml''',
      )
      ..addOption(
        'yaml-version',
        help: '''Option to completely change the version in pubspec.yaml''',
      )
      ..addOption(
        'homepage',
        help: '''Change the homepage url in pubspec.yaml''',
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
