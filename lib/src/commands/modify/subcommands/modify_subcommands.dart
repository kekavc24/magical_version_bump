import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:magical_version_bump/src/core/command_handlers/command_handlers.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:mason_logger/mason_logger.dart';

part 'bump_subcommand.dart';
part 'set_subcommand.dart';

// ignore: comment_references
/// Generic class for [ModifyCommand]. All subcommands will either:
///
/// * Allow modification of a single node
/// * Allow modification of multiple nodes
///
abstract class ModifySubCommand extends Command<int> {
  ModifySubCommand({required this.logger}) {
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
      )
      ..addOption(
        'set-version',
        help: '''Version to set''',
        aliases: ['ver'],
      )
      ..addOption(
        'set-prerelease',
        help: 'Prerelease version to set',
        aliases: ['pre'],
      )
      ..addOption(
        'set-build',
        help: 'Build metadata to append to version',
        aliases: ['build'],
      )
      ..addFlag(
        'keep-pre',
        help: 'Indicates old prerelease version should be retained',
        negatable: false,
      )
      ..addFlag(
        'keep-build',
        help: 'Indicates any existing build metadata should be retained',
        negatable: false,
      );
  }

  /// Logger for utility purposes
  final Logger logger;
}
