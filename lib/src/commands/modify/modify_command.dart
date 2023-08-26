import 'package:args/command_runner.dart';
import 'package:magical_version_bump/src/commands/modify/subcommands/modify_subcommands.dart';
import 'package:mason_logger/mason_logger.dart';

/// This command is the base command for all sub-commands that modify 1 or more
/// nodes in the yaml/json file
class ModifyCommand extends Command<int> {
  ModifyCommand({required Logger logger}) {
    addSubcommand(BumpSubcommand(logger: logger));
    addSubcommand(SetSubcommand(logger: logger));
  }

  @override
  String get name => 'modify';

  @override
  String get description => 'Modifies one or more nodes in a yaml/json file';

  @override
  String get invocation => 'mag modify <subcommand> [arguments]';

  @override
  String get summary => '$invocation\n$description';
}
