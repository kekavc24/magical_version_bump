import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

abstract base class RunnableCommand extends Command<int> {
  /// Function to run
  Future<void> runnable();

  @override
  FutureOr<int>? run() async {
    String wrapError(String message) => red.wrap(message)!;

    try {
      await runnable();
    } catch (e) {
      switch (e) {
        case PathNotFoundException(message: final message):
          print(wrapError(message));
          return ExitCode.osFile.code;

        case FormatException(message: final message):
          print(wrapError(message));
          return ExitCode.software.code;

        default:
          print(wrapError(e.toString()));
          return ExitCode.software.code;
      }
    }

    return ExitCode.success.code;
  }
}
