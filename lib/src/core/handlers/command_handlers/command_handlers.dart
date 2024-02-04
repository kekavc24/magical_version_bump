import 'package:args/args.dart';
import 'package:magical_version_bump/src/core/argument_normalizers/arg_normalizer.dart';
import 'package:magical_version_bump/src/core/custom_version_modifiers/semver_version_modifer.dart';
import 'package:magical_version_bump/src/core/handlers/file_handler/file_handler.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/counter/generic_counter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/magical_exception.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:mason_logger/mason_logger.dart';

part 'modify_command_handlers/bump_command_handler.dart';
part 'modify_command_handlers/set_command_handler.dart';
part 'walk_command_handlers/base.dart';
part 'walk_command_handlers/find_command_handler.dart';
part 'walk_command_handlers/replace_command_handler.dart';

/// Each command has a unique way to handle incoming arguments
abstract class CommandHandler with ValidateVersion, ModifyYaml {
  CommandHandler({required this.logger});

  /// For logging
  final Logger logger;

  /// File handler for file io operations
  late FileHandler _fileHandler;

  /// Argument checker that validates and preps arguments
  late ArgumentsNormalizer _argumentsNormalizer;

  /// Each subclass must implement this as each command has its own core logic.
  Future<void> _coreCommandHandler(ArgResults? argResults);

  /// Set up file handler
  void _setupFileHandler(ArgResults? argResults) {
    _fileHandler = FileHandler.fromParsedArgs(
      argResults,
      logger,
    );
  }

  /// Each subclass behaves differently based on args passed in by user. Thus
  /// must be overriden/implemented.
  void _setUpArgChecker(ArgResults? argResults);

  /// Handle command. Commands call this method with args the user passed
  /// in.
  Future<void> handleCommand(ArgResults? argResults) async {
    /// Args checker. Args must be validated before setting up any other
    /// utility classes.
    ///
    /// Throw any errors
    _setUpArgChecker(argResults);

    final validationProgress = logger.progress('Checking arguments');

    final validatedArgs = _argumentsNormalizer.validateArgs();

    if (!validatedArgs.isValid) {
      validationProgress.fail(validatedArgs.reason!.key);
      throw MagicalException(message: validatedArgs.reason!.value);
    }

    validationProgress.complete('Checked arguments');

    // Setup file handler for use
    _setupFileHandler(argResults);

    /// Any other operation will be handled by core logic.
    ///
    /// I'm leaving a wildcard for file reading as future functionality of
    /// this tool may require multiple files to be read from disk
    ///
    /// Same for file saving.
    await _coreCommandHandler(argResults);
  }

  /// Get arguments checker
  T _getChecker<T extends ArgumentsNormalizer>() => _argumentsNormalizer as T;
}
