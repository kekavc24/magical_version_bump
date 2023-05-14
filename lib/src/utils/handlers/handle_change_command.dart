import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:mason_logger/mason_logger.dart';

class HandleChangeCommand
    with
        HandleFile,
        NormalizeArgs,
        ValidatePreppedArgs,
        ValidateVersion,
        ModifyYaml {
  HandleChangeCommand({this.logger});

  final Logger? logger;

  /// Change specified node in yaml file
  Future<void> handleCommand(List<String> args) async {
    final prepProgress = logger!.progress('Checking arguments');

    // Normalize args & check validity
    final normalizedArgs = normalizeArgs(args);

    final preppedArgs = getArgAndValues(normalizedArgs);

    final invalidity = await validateArgs(
      preppedArgs.keys.toList(),
    );

    if (invalidity != null) {
      prepProgress.fail(invalidity.key);
      throw MagicalException(violation: invalidity.value);
    }

    prepProgress.complete('Checked arguments');

    // Read pubspec.yaml file
    final fileData = await readFile(
      requestPath: preppedArgs.containsKey('with-path'),
      logger: logger!,
    );

    var version = '';

    // If user wants version change, check if valid
    if (preppedArgs.containsKey('yaml-version')) {
      logger!.warn('Version flag detected. Must verify version is valid');

      version = await validateVersion(
        logger: logger!,
        version: preppedArgs['yaml-version'],
      );
    }

    // Set up re-usable file
    var editedFile = fileData.file;

    final changeProgress = logger!.progress('Changing yaml nodes');

    // Loop all entries
    final entries = preppedArgs.entries.where(
      (element) => element.key != 'with-path',
    );

    for (final entry in entries) {
      editedFile = await editYamlFile(
        editedFile,
        entry.key == 'yaml-version' ? 'version' : entry.key,
        entry.key == 'yaml-version' ? version : entry.value,
      );
    }

    changeProgress.complete('Changed all nodes');

    /// Save file changes
    await saveFile(data: editedFile, path: fileData.path, logger: logger!);

    /// Show success
    logger!.success('Updated your yaml file!');
  }
}
