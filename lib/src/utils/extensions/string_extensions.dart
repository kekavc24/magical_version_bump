import 'package:magical_version_bump/src/utils/enums/enums.dart';

extension Versioning on String {
  /// Get file type
  FileType get fileType => switch (this) {
        'yaml' => FileType.yaml,
        'json' => FileType.json,
        _ => FileType.unknown
      };

  /// Get modify strategy for bumping version
  ModifyStrategy get bumpStrategy => switch (this) {
        'absolute' => ModifyStrategy.absolute,
        _ => ModifyStrategy.relative
      };
}
