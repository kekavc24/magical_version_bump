import 'package:magical_version_bump/src/utils/enums/enums.dart';

extension Versioning on String {
  /// Get the bump type. Up or down
  BumpType get bumpType =>
      this == 'bump' || this == 'b' ? BumpType.up : BumpType.down;
}
