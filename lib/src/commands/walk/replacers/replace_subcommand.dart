part of '../walk_base_subcommands.dart';

/// Command for replacing values in a yaml/json file
class ReplaceSubCommand extends ReplacerTemplate {
  ReplaceSubCommand({required super.logger, required super.handler}) {
    argParser.addMultiOption(
      'values',
      help: 'Values to find',
      abbr: 'v',
      splitCommas: false,
    );
  }

  @override
  String get name => 'replace';

  @override
  String get description =>
      '''A subcommand that replaces a value/list of values in a yaml/json file''';
}
