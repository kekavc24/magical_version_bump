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

    // Set any version updated
    if (versionModifiers.build != null ||
        versionModifiers.prerelease != null ||
        versionModifiers.version != null) {
      var version = '';

      logger.warn('Version flag detected. Must verify version is valid');

      // Check version that user want to change to or the current version
      version = await validateVersion(
        versionModifiers.version ?? fileData.version,
        logger: logger,
      );

      Version? parsedOldVersion;

      String? updatedVersion;

      if (versionModifiers.keepPre ||
          versionModifiers.keepBuild ||
          versionModifiers.prerelease != null ||
          versionModifiers.build != null) {
        // Must not be null
        if (fileData.version == null) {
          throw MagicalException(
            violation: 'Old version cannot be empty/null',
          );
        }

        parsedOldVersion = Version.parse(fileData.version!);

        updatedVersion = Version.parse(
          version,
        ).setPreAndBuild(
          keepPre: versionModifiers.keepPre,
          keepBuild: versionModifiers.keepBuild,
          updatedPre:
              versionModifiers.keepPre && parsedOldVersion.preRelease.isNotEmpty
                  ? parsedOldVersion.preRelease.join('.')
                  : versionModifiers.prerelease,
          updatedBuild:
              versionModifiers.keepBuild && parsedOldVersion.build.isNotEmpty
                  ? parsedOldVersion.build.join('.')
                  : versionModifiers.build,
        );
      }

      editedFile = await updateYamlFile(
        editedFile,
        dictionary: (
          append: false,
          rootKeys: ['version'],
          data: updatedVersion ?? version,
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
