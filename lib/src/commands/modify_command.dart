import 'package:args/command_runner.dart';
import 'package:magical_version_bump/src/commands/handlers/command_handlers.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:mason_logger/mason_logger.dart';

/// This command modifies the version by bumping up or dumping down the
/// version number
class ModifyVersionCommand extends Command<int> {
  ModifyVersionCommand({
    required Logger logger,
  })  : _logger = logger,
        _handler = HandleModifyCommand(logger: logger) {
    argParser
      ..addFlag(
        'bump',
        abbr: 'b',
        help: 'Increments version by 1',
        negatable: false,
      )
      ..addFlag(
        'dump',
        abbr: 'd',
        help: 'Decrements version by 1',
        negatable: false,
      )
      ..addFlag(
        'major',
        help: 'Bumps up or bumps down the major version by 1',
        negatable: false,
      )
      ..addFlag(
        'minor',
        help: 'Bumps up or bumps down the minor version by 1',
        negatable: false,
      )
      ..addFlag(
        'patch',
        help: 'Bumps up or bumps down the patch version by 1',
        negatable: false,
      )
      ..addFlag(
        'build-number',
        help: 'Bumps up or bumps down the build number by 1',
        negatable: false,
      )
      ..addFlag(
        'with-path',
        help:
            '''Tells CLI to request file path instead of checking current directory''',
        negatable: false,
      )
      ..addOption(
        'set-path',
        help: '''Tell CLI where to check for a pubspec.yaml file''',
      )
      ..addFlag(
        'absolute',
        help:
            '''Tells CLI to bump each version independent of the other versions present''',
        negatable: false,
      )
      ..addFlag(
        'preset',
        help:
            '''Explicitly indicates that the tool should preset any version, prerelease and build info before bumping up/down the version''',
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
      );
  }

  @override
  String get description =>
      'A command that bumps up/down the version in the pubspec.yaml file';

  @override
  String get name => 'modify';

  final Logger _logger;
  final HandleModifyCommand _handler;

  @override
  Future<int> run() async {
    try {
      // Prep command first
      await _handler.handleCommand(argResults!.arguments);
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
