import 'package:args/args.dart';
import 'package:magical_version_bump/src/core/arg_sanitizers/arg_sanitizer.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_semver/pub_semver.dart';

part 'handle_set_command.dart';
part 'handle_bump_command.dart';

/// Each command has a unique way to handle incoming arguments
abstract class CommandHandler with HandleFile, ValidateVersion, ModifyYaml {
  CommandHandler({required this.logger});

  final Logger logger;

  /// Handle command
  void handleCommand(ArgResults? argResults);
}