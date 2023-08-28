import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

void main() {
  const version = '10.10.10-prerelease+21';

  group('relative versioning strategy', () {
    test('bumps major version', () {
      const expectedBumpedVersion = '11.0.0+21';

      final bumpedVersion = Version.parse(version).modifyVersion(
        versionTargets: ['major'],
        strategy: ModifyStrategy.relative,
      );

      expect(bumpedVersion.version, expectedBumpedVersion);
    });

    test('bumps minor version', () {
      const expectedBumpedVersion = '10.11.0+21';

      final bumpedVersion = Version.parse(version).modifyVersion(
        versionTargets: ['minor'],
        strategy: ModifyStrategy.relative,
      );

      expect(bumpedVersion.version, expectedBumpedVersion);
    });

    test('bumps patch version', () {
      const expectedBumpedVersion = '10.10.10+21';

      final bumpedVersion = Version.parse(version).modifyVersion(
        versionTargets: ['patch'],
        strategy: ModifyStrategy.relative,
      );

      expect(bumpedVersion.version, expectedBumpedVersion);
    });

    test('bumps build number', () {
      const expectedBumpedVersion = '10.10.10+22';

      final bumpedVersion = Version.parse(version).modifyVersion(
        versionTargets: ['build-number'],
        strategy: ModifyStrategy.relative,
      );

      expect(bumpedVersion.version, expectedBumpedVersion);
    });

    test('throws error if more than one target is passed in', () {
      expect(
        () => Version.parse(version).modifyVersion(
          versionTargets: ['major', 'minor'],
          strategy: ModifyStrategy.relative,
        ),
        throwsViolation(
          'Expected only one target for this versioning strategy',
        ),
      );
    });
  });

  group('absolute versioning strategy', () {
    test('bumps up the major version', () {
      const expectedBumpedVersion = '11.10.10-prerelease+21';

      final bumpedVersion = Version.parse(version).modifyVersion(
        versionTargets: ['major'],
        strategy: ModifyStrategy.absolute,
      );

      expect(bumpedVersion.version, expectedBumpedVersion);
    });

    test('bumps up minor version', () {
      const expectedBumpedVersion = '10.11.10-prerelease+21';

      final bumpedVersion = Version.parse(version).modifyVersion(
        versionTargets: ['minor'],
        strategy: ModifyStrategy.absolute,
      );

      expect(bumpedVersion.version, expectedBumpedVersion);
    });

    test('bumps up patch version', () {
      const expectedBumpedVersion = '10.10.11-prerelease+21';

      final bumpedVersion = Version.parse(version).modifyVersion(
        versionTargets: ['patch'],
        strategy: ModifyStrategy.absolute,
      );

      expect(bumpedVersion.version, expectedBumpedVersion);
    });

    test('bumps up build number', () {
      const expectedBumpedVersion = '10.10.10-prerelease+22';

      final bumpedVersion = Version.parse(version).modifyVersion(
        versionTargets: ['build-number'],
        strategy: ModifyStrategy.absolute,
      );

      expect(bumpedVersion.version, expectedBumpedVersion);
    });
  });

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

    test('sets new prerelease and keeps build-number', () {
      const updatedVersion = '10.10.10-alpha+21';

      final setPre = Version.parse(version).setPreAndBuild(
        updatedPre: 'alpha',
        keepBuild: true,
      );

      expect(setPre, updatedVersion);
    });

    test('sets new build-number and removes prerelease', () {
      const updatedVersion = '10.10.10+20';

      final setPre = Version.parse(version).setPreAndBuild(updatedBuild: '20');

      expect(setPre, updatedVersion);
    });

    test('sets new build-number and keeps prerelease', () {
      const updatedVersion = '10.10.10-prerelease+20';

      final setPre = Version.parse(version).setPreAndBuild(
        updatedBuild: '20',
        keepPre: true,
      );

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
      const versionWithBuild = '8.8.8+21';
      const versionWithCustomBuild = '8.8.8+MagicalVersionBump';

      final isValidNumber = Version.parse(versionWithBuild).buildIsNumber();
      final isCustom = !Version.parse(versionWithCustomBuild).buildIsNumber();

      expect(isValidNumber, true);
      expect(isCustom, true);
    });
  });
}
