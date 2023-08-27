part of 'command_handlers.dart';

class HandleSetCommand extends CommandHandler {
  HandleSetCommand({required super.logger});

  /// Change specified node in yaml file
  @override
  Future<void> handleCommand(ArgResults? argResults) async {
    // Start progress
    final prepProgress = logger.progress('Checking arguments');

    final sanitizer = SetArgumentSanitizer(argResults: argResults);

    // Validate and prep args simultaneously
    final preppedArgs = sanitizer.customValidate();

    if (!preppedArgs.isValid) {
      prepProgress.fail(preppedArgs.reason!.key);
      throw MagicalException(violation: preppedArgs.reason!.value);
    }

    prepProgress.complete('Checked arguments');

    final nodesAndValues = preppedArgs.nodesAndValues!;
    final checkedPath = sanitizer.pathInfo;
    final versionModifiers = sanitizer.modifiers(checkPreset: false);

    // Read pubspec.yaml file
    final fileData = await readFile(
      requestPath: checkedPath.requestPath,
      logger: logger,
      setPath: checkedPath.path,
    );

    var version = '';

    // If user wants version change, check if valid
    if (nodesAndValues.keys.contains('version') ||
        versionModifiers.prerelease != null ||
        versionModifiers.build != null ||
        versionModifiers.version != null) {
      logger.warn('Version flag detected. Must verify version is valid');

      // Check version that user want to change to or the current version
      version = await validateVersion(
        logger: logger,
        useYamlVersion: false,
        version:
            versionModifiers.version ?? fileData.yamlMap['version'] as String?,
      );
    }

    // Set up re-usable file
    var editedFile = fileData.file;

    final changeProgress = logger.progress('Updating nodes');

    final entries = nodesAndValues.entries;

    for (final node in entries) {
      editedFile = await editYamlFile(
        editedFile,
        node.key ,
        node.value,
      );
    }

    // Update any `set-prerelease` or `set-build` after version
    if (versionModifiers.build != null ||
        versionModifiers.prerelease != null ||
        versionModifiers.version != null) {
      final updatedVersion = Version.parse(
        versionModifiers.version ?? version,
      ).setPreAndBuild(
        keepPre: versionModifiers.keepPre,
        keepBuild: versionModifiers.keepBuild,
        updatedPre: versionModifiers.prerelease,
        updatedBuild: versionModifiers.build,
      );

      editedFile = await editYamlFile(editedFile, 'version', updatedVersion);
    }

    changeProgress.complete('Changed all nodes');

    /// Save file changes
    await saveFile(
      data: editedFile,
      path: fileData.path,
      logger: logger,
      type: fileData.type,
    );

    /// Show success
    logger.success('Updated your yaml file!');
  }
}
