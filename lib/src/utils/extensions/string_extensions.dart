import 'dart:convert';

import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:yaml/yaml.dart';

extension StringExtension on String {
  /// Get file type
  FileType get fileType => switch (this) {
        'yaml' || 'yml' => FileType.yaml,
        'json' => FileType.json,
        _ => FileType.unknown
      };

  /// Split and trim
  Iterable<String> splitAndTrim(String pattern) =>
      split(pattern).map((e) => e.trim());

  /// Convert file to dynamic map
  Map<String, dynamic> convertToMap() {
    return json.decode(
      json.encode(loadYaml(this)),
    ) as Map<String, dynamic>;
  }
}
