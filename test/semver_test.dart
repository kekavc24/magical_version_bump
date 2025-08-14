import 'package:checks/checks.dart';
import 'package:magical_version_bump/src/sem_ver/semver.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('parses version correctly', () {
    check(SemVer.parse('0.0.0-null+null', canCompareBuild: true)).equals(
      SemVer.rawUnchecked(
        0,
        0,
        0,
        prerelease: const ['null'],
        buildMetadata: const ['null'],
      ),
    );
  });

  test('throws error if core version is incorrect', () {
    check(() => SemVer.parse('0.0', canCompareBuild: true))
        .throws<FormatException>()
        .has((err) => err.message, 'message')
        .equals(
          'Invalid SemVer version string. Expected <major>.<minor>.<patch>',
        );
  });

  test('throws error if pre-release is invalid', () {
    check(() => SemVer.parse('0.0.0-pre*', canCompareBuild: true))
        .throws<FormatException>()
        .has((err) => err.message, 'message')
        .equals(
          'Invalid SemVer version string. Expected a valid pre-release version',
        );
  });

  test('throws error if build version is invalid', () {
    check(() => SemVer.parse('0.0.0-pre+*', canCompareBuild: true))
        .throws<FormatException>()
        .has((err) => err.message, 'message')
        .equals(
          'Invalid SemVer version string. Expected valid build metadata',
        );
  });
}
