import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/extensions/iterable_extension.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:mason_logger/mason_logger.dart';

class HandleModifyCommand
    with
        NormalizeArgs,
        ValidatePreppedArgs,
        HandleFile,
        ValidateVersion,
        ModifyYaml {
  HandleModifyCommand({this.logger});

  final Logger? logger;

  /// Modify the version in pubspec.yaml
  Future<void> handleCommand(List<String> args) async {
    // Command progress
    final prepProgress = logger!.progress('Checking arguments');

    // Normalize args & check validity
    final normalizedArgs = normalizeArgs(args);

    final invalidity = await validateArgs(
      normalizedArgs.args,
      isModify: true,
      userSetPath: normalizedArgs.hasPath,
      logger: logger!,
    );

    if (invalidity != null) {
      prepProgress.fail(invalidity.key);
      throw MagicalException(violation: invalidity.value);
    }

    final preppedArgs = prepArgs(normalizedArgs.args);

    prepProgress.complete('Checked arguments');

    // Read pubspec.yaml file
    final fileData = await readFile(
      requestPath: preppedArgs.requestPath,
      logger: logger!,
      setPath: normalizedArgs.setPath,
    );

    // Validate version and get correct version
    final currentVersion = await validateVersion(
      logger: logger!,
      isModify: true,
      yamlMap: fileData.yamlMap,
    );

    // Modify the version
    final modProgress = logger!.progress(
      preppedArgs.action == 'b' || preppedArgs.action == 'bump'
          ? 'Bumping up version'
          : 'Bumping down version',
    );

    final modifiedVersion = await dynamicBump(
      preppedArgs.action,
      preppedArgs.absoluteVersioning
          ? preppedArgs.versionTargets
          : preppedArgs.versionTargets.getRelative(),
      currentVersion,
      absoluteVersioning: preppedArgs.absoluteVersioning,
    );

    final modifiedFile = await editYamlFile(
      fileData.file,
      'version',
      modifiedVersion,
    );

    modProgress.complete('Modified version');

    /// Save file changes
    await saveFile(
      data: modifiedFile,
      path: fileData.path,
      logger: logger!,
    );

    /// Show success
    logger!.success(
      """Version ${preppedArgs.action == 'b' || preppedArgs.action == 'bump' ? 'bumped up' : 'bumped down'} from $currentVersion to $modifiedVersion""",
    );
  }
}
