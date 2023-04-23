import 'dart:io';

import 'package:yaml_edit/yaml_edit.dart';

import 'helpers.dart';

/// Get version from fake.yaml before test starts
Future<String> readFileVersion() async {
  const path = 'test/files/fake.yaml';

  final file = await File(path).readAsString();

  return getVersion(file);
}

/// Reset file to initial version
Future<void> resetFile() async {
  const path = 'test/files/fake.yaml';
  const version = '10.10.10+10';

  final file = await File(path).readAsString();
  final yamlEdit = YamlEditor(file)..update(['version'], version);

  await File(path).writeAsString(yamlEdit.toString());
}
