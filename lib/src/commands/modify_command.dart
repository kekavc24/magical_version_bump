import 'package:args/command_runner.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:mason_logger/mason_logger.dart';

/// This command modifies the version by bumping up or dumping down the
/// version number
class ModifyVersion extends Command<int>
    with PrepCommand, HandleFile, ModifyYamlFile {
  ModifyVersion({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addFlag(
        'bump',
        abbr: 'b',
        help: 'Increments version by 1',
        negatable: false,
      )
      ..addFlag(
        'dump',
        abbr: 'd',
        help: 'Decrements version by 1',
        negatable: false,
      )
      ..addFlag(
        'major',
        help: 'Bumps up or bumps down the major version by 1',
        negatable: false,
      )
      ..addFlag(
        'minor',
        help: 'Bumps up or bumps down the minor version by 1',
        negatable: false,
      )
      ..addFlag(
        'patch',
        help: 'Bumps up or bumps down the patch version by 1',
        negatable: false,
      )
      ..addFlag(
        'build-number',
        help: 'Bumps up or bumps down the build number by 1',
        negatable: false,
      )
      ..addFlag(
        'with-path',
        help:
            '''Tells CLI to request file path instead of checking current directory''',
        negatable: false,
      );
  }

  @override
  String get description =>
      'A command that bumps up/down the version in the pubspec.yaml file';

  @override
  String get name => 'modify';

  final Logger _logger;

  @override
  Future<int> run() async {
    try {
      // Prep command first
      final prepData = await readArgs(
        args: argResults!.arguments,
        logger: _logger,
      );

      // Read file
      final yamlData = await readFile(
        requestPath: prepData.requestPath,
        logger: _logger,
      );

      // Modify file
      final modifiedData = await modifyFile(
        absoluteChange: false,
        action: prepData.action,
        targets: prepData.versionTargets,
        yamlData: yamlData,
        logger: _logger,
      );

      // Save changes
      await saveFile(data: modifiedData, logger: _logger);
    } on MagicalException catch (e) {
      _logger.err(e.toString());

      return ExitCode.usage.code;
    } on Exception catch (e) {
      _logger.err(e.toString());

      return ExitCode.software.code;
    }
    _logger.success('Version has been modified!');
    return ExitCode.success.code;
  }
}
