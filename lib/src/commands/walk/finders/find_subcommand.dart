part of '../walk_base_subcommands.dart';

/// Command for finding keys/values in a yaml/json file
class FindSubCommand extends WalkSubCommand {
  FindSubCommand({required super.logger, required super.handler}) {
    argParser
      ..addMultiOption(
        'keys',
        help: 'Keys to find',
        abbr: 'k',
      )
      ..addMultiOption(
        'values',
        help: 'Values to find',
        abbr: 'v',
      )
      ..addMultiOption(
        'pairs',
        help: 'Key-Value pair to find',
        abbr: 'p',
        splitCommas: false,
      )
      ..addOption(
        'key-order',
        help: 'Order based on provided key/values',
        aliases: ['ko'],
        defaultsTo: 'loose',
        allowed: ['loose', 'grouped', 'strict'],
      );
    // ..addMultiOption(
    //   'bounds',
    //   help: 'Targets to use "aggregate" argument passed',
    //   abbr: 'b',
    //   allowed: ['keys', 'values', 'pairs'],
    // );
  }

  @override
  String get name => 'find';

  @override
  String get description =>
      '''A subcommand that finds exact values for a key/value in a yaml/json file''';
}
