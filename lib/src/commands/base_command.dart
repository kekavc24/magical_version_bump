import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// Abstract command used by all commands
abstract class MagicalCommand extends Command<int> {
  MagicalCommand({required this.logger}) {
    argParser
      ..addFlag(
        'request-path',
        help: 'Prompt for directory to find yaml/json file',
        negatable: false,
        aliases: ['reqPath'],
      )
      ..addOption(
        'directory',
        help: 'Directory where to find yaml/json file',
        aliases: ['dir'],
        defaultsTo: 'pubspec.yaml',
      );
  }

  /// Logger for utility purposes
  final Logger logger;
}
