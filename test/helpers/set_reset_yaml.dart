part of 'helpers.dart';

/// Get file path for
String getTestFile() => 'fake.yaml';

/// Get version from fake.yaml before test starts
Future<String> readFileNode(String node) async {
  final path = getTestFile();

  final file = await File(path).readAsString();

  return getNodeValue(file, node);
}

/// Reset file to initial version
Future<void> resetFile({
  bool remove = false,
  String node = 'version',
  String nodeValue = '10.10.10+10',
}) async {
  final path = getTestFile();
  final file = await File(path).readAsString();

  final yamlEdit = YamlEditor(file);

  if (remove) {
    yamlEdit.remove([node]);
  } else {
    yamlEdit.update([node], nodeValue);
  }

  await File(path).writeAsString(yamlEdit.toString());
}
