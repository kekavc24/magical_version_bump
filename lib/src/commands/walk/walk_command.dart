import 'package:magical_version_bump/src/commands/base_commands.dart';
import 'package:magical_version_bump/src/commands/walk/walk_base_subcommands.dart';
import 'package:magical_version_bump/src/core/handlers/command_handlers/command_handlers.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';

/// This command is the base command for all commands that "walk" nodes of a
/// yaml/json to read or read & modify it
class WalkCommand extends MagicalCommand {
  WalkCommand({required super.logger}) {
    addSubcommand(
      FindSubCommand(
        logger: logger,
        handler: HandleFindCommand(logger: logger),
      ),
    );
    addSubcommand(
      RenameSubCommand(
        logger: logger,
        handler: HandleReplaceCommand(
          logger: logger,
          subCommandType: WalkSubCommandType.rename,
        ),
      ),
    );
    addSubcommand(
      ReplaceSubCommand(
        logger: logger,
        handler: HandleReplaceCommand(
          logger: logger,
          subCommandType: WalkSubCommandType.replace,
        ),
      ),
    );
  }

  @override
  String get name => 'walk';

  @override
  String get description =>
      '"Walks" to one or more nodes to read or read & modify them in a yaml/json file';

  @override
  String get invocation => 'mag walk <subcommand> [arguments]';

  @override
  String get summary => '$invocation\n$description';
}
