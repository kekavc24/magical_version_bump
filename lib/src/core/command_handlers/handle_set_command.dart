part of 'command_handlers.dart';

class HandleSetCommand extends CommandHandler {
  HandleSetCommand({required super.logger});

  /// Change specified node in yaml file
  @override
  Future<void> handleCommand(ArgResults? argResults) async {
    // Start progress
    final prepProgress = logger.progress('Checking arguments');

    final sanitizer = SetArgumentsChecker(argResults: argResults);

    /// Use default validation.
    final validatedArgs = sanitizer.defaultValidation();

    if (!validatedArgs.isValid) {
      prepProgress.fail(validatedArgs.reason!.key);
      throw MagicalException(
        violation: validatedArgs.reason!.value,
      );
    }

    final checkedPath = argResults!.pathInfo;
    final preppedArgs = sanitizer.prepArgs();

    final versionModifiers = preppedArgs.modifiers;

    prepProgress.complete('Checked arguments');

    // Read pubspec.yaml file
    final fileData = await readFile(
      requestPath: checkedPath.requestPath,
      logger: logger,
      setPath: checkedPath.path,
    );

    // Set up re-usable file
    var editedFile = fileData.file;

    final changeProgress = logger.progress('Updating nodes');

    if (preppedArgs.dictionaries.isNotEmpty) {
      for (final dictionary in preppedArgs.dictionaries) {
        editedFile = await updateYamlFile(editedFile, dictionary: dictionary);
      }
    }

    /// Incase `set-version` was used instead of using the `dictionary` syntax,
    /// update it
    if (versionModifiers.build != null ||
        versionModifiers.prerelease != null ||
        versionModifiers.version != null) {
      final version = MagicalSEMVER.addPresets(
        fileData.version ?? '',
        modifiers: versionModifiers,
      );

      editedFile = await updateYamlFile(
        editedFile,
        dictionary: (
          append: false,
          rootKeys: ['version'],
          data: version,
        ),
      );
    }

    changeProgress.complete('Changed all nodes');

    /// Save file changes
    await saveFile(
      file: editedFile,
      path: fileData.path,
      logger: logger,
      type: fileData.fileType,
    );

    /// Show success
    logger.success('Updated your yaml file!');
  }
}
