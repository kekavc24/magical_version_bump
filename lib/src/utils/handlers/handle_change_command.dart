import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_semver/pub_semver.dart';

typedef ChangeableNodes = Iterable<MapEntry<String, String>>;

class HandleChangeCommand
    with
        HandleFile,
        NormalizeArgs,
        ValidatePreppedArgs,
        ValidateVersion,
        ModifyYaml {
  HandleChangeCommand({required this.logger});

  final Logger logger;

  /// Change specified node in yaml file
  Future<void> handleCommand(List<String> args) async {
    final prepProgress = logger.progress('Checking arguments');

    // Normalize args & check validity
    final normalizedArgs = normalizeArgs(args);

    final preppedArgs = getArgAndValues(normalizedArgs.args);

    final validatedArgs = await validateArgs(
      preppedArgs.keys.toList(),
      userSetPath: normalizedArgs.hasPath,
      logger: logger,
    );

    if (validatedArgs.invalidReason != null) {
      prepProgress.fail(validatedArgs.invalidReason!.key);
      throw MagicalException(violation: validatedArgs.invalidReason!.value);
    }

    prepProgress.complete('Checked arguments');

    // Read pubspec.yaml file
    final fileData = await readFile(
      requestPath: validatedArgs.args.contains('with-path'),
      logger: logger,
      setPath: normalizedArgs.setPath,
    );

    var version = '';

    // If user wants version change, check if valid
    if (validatedArgs.args.contains('yaml-version') ||
        validatedArgs.args.contains('set-prelease') ||
        validatedArgs.args.contains('set-build')) {
      logger.warn('Version flag detected. Must verify version is valid');

      // Check version that user want to change to or the current version 
      version = await validateVersion(
        logger: logger,
        version: preppedArgs['yaml-version'] ??
            fileData.yamlMap['version'] as String?,
      );
    }

    // Set up re-usable file
    var editedFile = fileData.file;

    final changeProgress = logger.progress('Changing yaml nodes');

    // Loop all entries and match with validated args
    final validMap = validatedArgs.args.fold(
      <String, String>{},
      (previousValue, element) {
        previousValue.addAll({element: preppedArgs[element] ?? ''});
        return previousValue;
      },
    );

    final entries = validMap.entries.where(
      (element) => element.key != 'with-path',
    );

    // Check if user wanted to change prelease or build
    final checkedNodes = checkNodes(entries);

    for (final node in checkedNodes.nodes) {
      editedFile = await editYamlFile(
        editedFile,
        node.key == 'yaml-version' ? 'version' : node.key,
        node.key == 'yaml-version' ? version : node.value,
      );
    }

    // Update any 'set-prelease' or 'set-build' options after 'yaml-version'
    if (checkedNodes.build != null || checkedNodes.pre != null) {
      final updatedVersion = Version.parse(version).setPreAndBuild(
        keepPre: checkedNodes.keepPre,
        keepBuild: checkedNodes.keepBuild,
        updatedPre: checkedNodes.pre,
        updatedBuild: checkedNodes.build,
      );

      editedFile = await editYamlFile(editedFile, 'version', updatedVersion);
    }

    changeProgress.complete('Changed all nodes');

    /// Save file changes
    await saveFile(data: editedFile, path: fileData.path, logger: logger);

    /// Show success
    logger.success('Updated your yaml file!');
  }

  /// Check whether prelease or build are being modified
  ({
    ChangeableNodes nodes,
    bool keepPre,
    bool keepBuild,
    String? pre,
    String? build,
  }) checkNodes(
    ChangeableNodes nodes,
  ) {
    var keepPre = false;
    var keepBuild = false;
    String? pre;
    String? build;

    final modifiedNodes = nodes.fold(
      <MapEntry<String, String>>[],
      (previousValue, element) {
        switch (element.key) {
          case 'keep-pre':
            keepPre = true;
            break;

          case 'keep-build':
            keepBuild = true;
            break;

          case 'set-build':
            build = element.value.isEmpty ? null : element.value;
            break;

          case 'set-prelease':
            pre = element.value.isEmpty ? null : element.value;
            break;

          default:
            previousValue.add(element);
        }
        return previousValue;
      },
    );

    return (
      nodes: modifiedNodes,
      keepPre: keepPre,
      keepBuild: keepBuild,
      pre: pre,
      build: build,
    );
  }
}
