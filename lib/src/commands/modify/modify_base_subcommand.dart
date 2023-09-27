import 'package:magical_version_bump/src/commands/base_command.dart';

part 'subcommands/bump_subcommand.dart';
part 'subcommands/set_subcommand.dart';

// ignore: comment_references
/// Generic class for [ModifyCommand]. All subcommands will either:
///
/// * Allow modification of a single node - `Bump` subcommand
/// * Allow modification of multiple nodes - `Set` subcommand
///
abstract class ModifySubCommand extends RunnableCommand {
  ModifySubCommand({required super.logger, required super.handler}) {
    argParser
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
}
