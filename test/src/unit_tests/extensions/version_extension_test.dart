import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';


void main() {
  const version = '10.10.10-prerelease+21';
  const versionWithCustomBuild = '8.8.8+MagicalVersionBump';

  group('general extension functionality', () {
    test('returns next major version', () {
      final relativeVersion = Version.parse(version).nextRelativeVersion(
        'major',
      );

      expect(relativeVersion.toString(), '11.0.0');
    });

    test('returns next minor version', () {
      final relativeVersion = Version.parse(version).nextRelativeVersion(
        'minor',
      );

      expect(relativeVersion.toString(), '10.11.0');
    });

    test('returns next patch version', () {
      final relativeVersion = Version.parse(version).nextRelativeVersion(
        'patch',
      );

      expect(relativeVersion.toString(), '10.10.10');
    });

    test('returns valid map of versions', () {
      final map = Version.parse(version).getVersionAsMap();

      expect(map, equals({'major': 10, 'minor': 10, 'patch': 10}));
    });

    test('sets new prerelease and removes build-number', () {
      const updatedVersion = '10.10.10-alpha';

      final setPre = Version.parse(version).setPreAndBuild(updatedPre: 'alpha');

      expect(setPre, updatedVersion);
    });

    test('sets new build-number and removes prerelease', () {
      const updatedVersion = '10.10.10+20';

      final setPre = Version.parse(version).setPreAndBuild(updatedBuild: '20');

      expect(setPre, updatedVersion);
    });

    test('sets both prerelease and build-number', () {
      const updatedVersion = '10.10.10-alpha+20';

      final setPre = Version.parse(version).setPreAndBuild(
        updatedPre: 'alpha',
        updatedBuild: '20',
      );

      expect(setPre, updatedVersion);
    });

    test('checks if build number can be bumped', () {
      final isValidNumber = Version.parse(version).buildIsNumber();
      final isCustom = !Version.parse(versionWithCustomBuild).buildIsNumber();

      expect(isValidNumber, true);
      expect(isCustom, true);
    });
  });
}
