import 'package:magical_version_bump/src/commands/base_command.dart';
import 'package:magical_version_bump/src/commands/modify/modify_base_subcommand.dart';

/// This command is the base command for all sub-commands that modify 1 or more
/// nodes in the yaml/json file
class ModifyCommand extends MagicalCommand {
  ModifyCommand({required super.logger}) {
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
