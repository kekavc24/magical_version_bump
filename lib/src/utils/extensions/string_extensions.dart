import 'package:magical_version_bump/src/utils/enums/enums.dart';

extension ActionType on String {
  BumpType get bumpType =>
      this == 'bump' || this == 'b' ? BumpType.up : BumpType.down;
}
