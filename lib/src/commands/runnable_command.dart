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
      if (e case PathNotFoundException(message: final message)) {
        print(wrapError(message));
        return ExitCode.ioError.code;
      }

      rethrow;
    }

    return ExitCode.success.code;
  }
}
