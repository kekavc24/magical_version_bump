import 'dart:io';

import 'package:magical_version_bump/src/command_runner.dart';
import 'package:magical_version_bump/src/commands/base_commands.dart';
import 'package:magical_version_bump/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

/// {@template update_command}
/// A command which updates the CLI.
/// {@endtemplate}
class UpdateCommand extends MagicalCommand {
  /// {@macro update_command}
  UpdateCommand({
    required super.logger,
    PubUpdater? pubUpdater,
  })  : _logger = logger,
        _pubUpdater = pubUpdater ?? PubUpdater();

  final Logger _logger;
  final PubUpdater _pubUpdater;

  @override
  String get description => 'Update the CLI.';

  static const String commandName = 'update';

  @override
  String get name => commandName;

  @override
  Future<int> run() async {
    final updateCheckProgress = _logger.progress('Checking for updates');
    late final String latestVersion;
    try {
      latestVersion = await _pubUpdater.getLatestVersion(packageName);
    } catch (error) {
      updateCheckProgress.fail();
      _logger.err('$error');
      return ExitCode.software.code;
    }
    updateCheckProgress.complete('Checked for updates');

    final isUpToDate = packageVersion == latestVersion;
    if (isUpToDate) {
      _logger.info('CLI is already at the latest version.');
      return ExitCode.success.code;
    }

    final updateProgress = _logger.progress('Updating to $latestVersion');

    late final ProcessResult result;
    try {
      result = await _pubUpdater.update(
        packageName: packageName,
        versionConstraint: latestVersion,
      );
    } catch (error) {
      updateProgress.fail();
      _logger.err('$error');
      return ExitCode.software.code;
    }

    if (result.exitCode != ExitCode.success.code) {
      updateProgress.fail();
      _logger.err('Error updating CLI: ${result.stderr}');
      return ExitCode.software.code;
    }

    updateProgress.complete('Updated to $latestVersion');

    return ExitCode.success.code;
  }
}
