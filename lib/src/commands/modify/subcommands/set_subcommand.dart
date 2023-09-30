part of '../modify_base_subcommand.dart';

/// This command modifies several nodes of yaml file
class SetSubcommand extends ModifySubCommand {
  SetSubcommand({required super.logger, required super.handler}) {
    argParser
      ..addMultiOption(
        'dictionary',
        help: 'Specify a key to add/overwrite and value(s) separated with "="',
        aliases: ['dict'],
        splitCommas: false,
      )
      ..addMultiOption(
        'add',
        help: 'Specify a key to append value(s) to separated with "="',
        splitCommas: false,
      );
  }

  @override
  String get name => 'set';

  @override
  String get description =>
      'A subcommand that adds, appends a value or overwrites a node in a yaml/json file';
}
