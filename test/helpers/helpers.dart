import 'dart:io';

import 'package:args/args.dart';
import 'package:magical_version_bump/src/core/argument_normalizers/arg_normalizer.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/data/version_modifiers.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/magical_exception.dart';
import 'package:magical_version_bump/src/utils/extensions/map_extensions.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

part 'custom_matchers.dart';
part 'set_reset_yaml.dart';
part 'set_up_sanitizers.dart';
part 'read_nested_nodes.dart';
part 'version_modifier.dart';
part 'matched_node_builder.dart';
