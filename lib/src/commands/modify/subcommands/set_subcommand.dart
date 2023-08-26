part of 'modify_subcommands.dart';

// TODO: Add append flag & figure out how to add multiple values in nodes

/// This command modifies several nodes of yaml file
class SetSubcommand extends ModifySubCommand {
  SetSubcommand({required super.logger}) {
    argParser
      ..addOption(
        'name',
        help: 'Change the name in pubspec.yaml',
      )
      ..addOption(
        'description',
        help: 'Change the description of your project in pubspec.yaml',
        aliases: ['desc'],
      )
      ..addOption(
        'homepage',
        help: 'Change the homepage url in pubspec.yaml',
      )
      ..addOption(
        'repository',
        help: '''Change the repository url for project in pubspec.yaml''',
      )
      ..addOption(
        'issue_tracker',
        help: '''Change the url pointing to an issue tracker in pubspec.yaml''',
      )
      ..addOption(
        'documentation',
        help:
            '''Change the url pointing to your project's documentation in pubspec.yaml''',
      );
  }

  @override
  String get name => 'set';

  @override
  String get description =>
      'A subcommand that adds, appends a value or overwrites a node in a yaml/json file';
}
