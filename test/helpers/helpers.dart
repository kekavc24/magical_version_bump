import 'dart:io';

import 'package:args/args.dart';
import 'package:magical_version_bump/src/core/arg_sanitizers/arg_sanitizer.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

part 'magical_exception_message.dart';
part 'set_reset_yaml.dart';
part 'set_up_sanitizers.dart';
part 'version_from_yaml.dart';
