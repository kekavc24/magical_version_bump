part of '../walk_base_subcommands.dart';

/// Command for replacing values in a yaml/json file
class RenameSubCommand extends ReplacerTemplate {
  RenameSubCommand({required super.logger, required super.handler}) {
    argParser.addMultiOption(
      'keys',
      help: 'Keys to find',
      abbr: 'k',
      splitCommas: false,
    );
  }

  @override
  String get name => 'rename';

  @override
  String get description =>
      '''A subcommand that renames a key/list of keys in a yaml/json file''';
}
