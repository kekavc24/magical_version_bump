import 'package:args/command_runner.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:mason_logger/mason_logger.dart';

/// This command overwrites/writes the version in the pubspec.yaml
class ChangeVersion extends Command<int> {
  ChangeVersion({
    required Logger logger,
  }) : _logger = logger {
    argParser.addFlag(
      'with-path',
      help:
          '''Tells CLI to request file path instead of checking current directory''',
      negatable: false,
    );
  }

  @override
  String get description =>
      'A command that adds/overwrites the version specified in the pubspec.yaml file';

  @override
  String get name => 'change';

  final Logger _logger;

  @override
  Future<int> run() async {
    try {
      // Check if user wants to provide a path
      final requestPath = argResults!['with-path'] == true;
      final absoluteVersion =
          argResults!.rest.isEmpty ? null : argResults!.rest.first;

      // Read file
    } on MagicalException catch (e) {
      _logger.err(e.toString());

      return ExitCode.usage.code;
    } on Exception catch (e) {
      _logger.err(e.toString());

      return ExitCode.software.code;
    }
    _logger.success('Version has been changed!');
    return ExitCode.success.code;
  }
}
