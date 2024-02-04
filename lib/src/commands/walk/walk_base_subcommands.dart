import 'package:magical_version_bump/src/commands/base_commands.dart';

part 'finders/find_subcommand.dart';
part 'replacers/rename_subcommand.dart';
part 'replacers/replace_subcommand.dart';

/// Base parent for finder and replacer subcommands which has shared properties
abstract class WalkSubCommand extends MultiDirectoryCommand {
  WalkSubCommand({required super.logger, required super.handler}) {
    argParser
      ..addOption(
        'view-format',
        help: 'Output to console based on "walk" output',
        aliases: ['vf'],
        defaultsTo: 'grouped',
        allowed: ['grouped', 'live', 'hide'],
      )
      ..addOption(
        'aggregate',
        help: 'Type of count to use on "walk"',
        abbr: 'a',
        defaultsTo: 'all',
        allowed: ['all', 'count', 'first'],
      )
      ..addOption(
        'limit-to',
        help:
            '''Denotes upper limit for "aggregate". Requires a numeric value for "count".''',
        aliases: ['lmt'],
        defaultsTo: '',
      );
  }
}

/// Base class for replacer command
abstract class ReplacerTemplate extends WalkSubCommand {
  ReplacerTemplate({required super.logger, required super.handler}) {
    argParser.addMultiOption(
      'subtitute',
      help: 'Replacement for value(s) provided',
      abbr: 's',
    );
  }
}
