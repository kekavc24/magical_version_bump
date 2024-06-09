import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:magical_version_bump/src/core/handlers/command_handlers/command_handlers.dart';
import 'package:magical_version_bump/src/utils/exceptions/exceptions.dart';
import 'package:mason_logger/mason_logger.dart';

/// Abstract command used by all commands. Every command or subcommand will
/// have access to the `request-path` flag
///
/// This class will **ONLY** be extended by commands that :
///   * Have a set of subcommands
///   * Define a set of flags, options or multiOptions accessible only to the
///     command itself or its subcommands.
///
abstract class MagicalCommand extends Command<int> {
  MagicalCommand({required this.logger});

  /// Logger for utility purposes
  final Logger logger;
}

/// Generic runnable command template. Will be extended by commands or
/// subcommands that are "run"-able.
abstract class RunnableCommand extends MagicalCommand {
  RunnableCommand({required super.logger, required this.handler}) {
    argParser.addFlag(
      'request-path',
      help: 'Prompt for directory to find yaml/json file',
      negatable: false,
      aliases: ['reqPath'],
    );
  }

  /// Each command will always have a handler class with custom logic
  final CommandHandler handler;

  @override
  Future<int> run() async {
    try {
      await handler.handleCommand(argResults);
    } on MagicalException catch (e) {
      logger.err(e.toString());

      return ExitCode.usage.code;
    } on PathNotFoundException catch (e) {
      logger.err(e.message);

      return ExitCode.osFile.code;
    } catch (e) {
      logger.err(e.toString());

      return ExitCode.software.code;
    }
    return ExitCode.success.code;
  }
}

/// A command that reads a yaml/json from a single directory
abstract class SingleDirectoryCommand extends RunnableCommand {
  SingleDirectoryCommand({required super.logger, required super.handler}) {
    argParser.addOption(
      'directory',
      help: 'Directory where to find yaml/json file',
      aliases: ['dir'],
      defaultsTo: 'pubspec.yaml',
    );
  }
}

/// A command that can read yaml/json files from multiple directories
abstract class MultiDirectoryCommand extends RunnableCommand {
  MultiDirectoryCommand({required super.logger, required super.handler}) {
    argParser.addMultiOption(
      'directory',
      help: 'Directory where to find yaml/json files',
      aliases: ['dir'],
    );
  }
}
