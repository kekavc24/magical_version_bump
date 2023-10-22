import 'dart:io';

import 'package:args/args.dart';
import 'package:magical_version_bump/src/core/argument_checkers/arg_checker.dart';
import 'package:magical_version_bump/src/utils/data/version_modifiers.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/extensions/map_extensions.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

part 'magical_exception_message.dart';
part 'set_reset_yaml.dart';
part 'set_up_sanitizers.dart';
part 'read_nested_nodes.dart';
part 'version_modifier.dart';
