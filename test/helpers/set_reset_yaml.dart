import 'dart:io';

import 'package:yaml_edit/yaml_edit.dart';

import 'helpers.dart';

/// Read current directory
String getTestPath() {
  var dir = Directory.current.path;
  if (dir.endsWith('/test')) {
    dir = dir.replaceAll('/test', '');
  }

  return '$dir/test/files/fake.yaml';
}

/// Get version from fake.yaml before test starts
Future<String> readFileVersion() async {
  final path = getTestPath();

  final file = await File(path).readAsString();

  return getYamlValue(file, 'version');
}

/// Reset file to initial version
Future<void> resetFile() async {
  final path = getTestPath();
  const version = '10.10.10+10';

  final file = await File(path).readAsString();
  final yamlEdit = YamlEditor(file)..update(['version'], version);

  await File(path).writeAsString(yamlEdit.toString());
}
