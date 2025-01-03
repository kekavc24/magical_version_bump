import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

abstract base class RunnableCommand extends Command<int> {
  RunnableCommand(this.logger);

  final Logger logger;

  /// Function to run
  Future<int?> runnable();

  @override
  Future<int> run() async {
    int? code;

    try {
      code = await runnable();
    } catch (e) {
      switch (e) {
        case PathNotFoundException(message: final message):
          logger.err(message);
          return ExitCode.ioError.code;

        // Catch format exceptions for a runnable command
        case FormatException(message: final message):
          logger.err(message);
          return ExitCode.usage.code;

        // Rethrow other exceptions to be caught top-level
        default:
          rethrow;
      }
    }

    return code ?? ExitCode.success.code;
  }
}
