import 'package:magical_version_bump/src/core/enums/enums.dart';
import 'package:magical_version_bump/src/core/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/core/extensions/extensions.dart';
import 'package:magical_version_bump/src/core/mixins/command_mixins.dart';
import 'package:magical_version_bump/src/utils/arg_sanitizers/arg_sanitizer.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_semver/pub_semver.dart';

part 'handle_change_command.dart';
part 'handle_modify_command.dart';

/// Each command has a unique way to handle incoming arguments
abstract class CommandHandler with HandleFile, ValidateVersion, ModifyYaml {
  /// Handle command
  void handleCommand(List<String> args);
}
