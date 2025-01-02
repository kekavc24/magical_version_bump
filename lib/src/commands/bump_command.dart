import 'package:args/command_runner.dart';
import 'package:magical_version_bump/src/commands/semver_subcommand.dart';
import 'package:mason_logger/mason_logger.dart';

final class BumpCommand extends Command<int> {
  BumpCommand(Logger logger) {
    addSubcommand(SemverSubcommand(logger));
  }

  @override
  String get description =>
      'A command that bumps a valid version (in json/yaml file path)';

  @override
  String get name => 'bump';
}
