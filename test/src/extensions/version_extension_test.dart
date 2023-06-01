import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/version_extension.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../../helpers/helpers.dart';

void main() {
  const version = '10.10.10-prerelease+21';

  group('relative versioning strategy', () {
    test('bumps major version', () {
      const expectedBumpedVersion = '11.0.0+21';

      final bumpedVersion = Version.parse(version).modifyVersion(
        BumpType.up,
        versionTargets: ['major'],
      );

      expect(bumpedVersion, expectedBumpedVersion);
    });

    test('bumps minor version', () {
      const expectedBumpedVersion = '10.11.0+21';

      final bumpedVersion = Version.parse(version).modifyVersion(
        BumpType.up,
        versionTargets: ['minor'],
      );

      expect(bumpedVersion, expectedBumpedVersion);
    });

    test('bumps patch version', () {
      const expectedBumpedVersion = '10.10.10+21';

      final bumpedVersion = Version.parse(version).modifyVersion(
        BumpType.up,
        versionTargets: ['patch'],
      );

      expect(bumpedVersion, expectedBumpedVersion);
    });

    test('bumps build number', () {
      const expectedBumpedVersion = '10.10.10+22';

      final bumpedVersion = Version.parse(version).modifyVersion(
        BumpType.up,
        versionTargets: ['build-number'],
      );

      expect(bumpedVersion, expectedBumpedVersion);
    });

    test('throws error if more than one target is passed in', () {
      expect(
        () => Version.parse(version).modifyVersion(
          BumpType.up,
          versionTargets: ['major', 'minor'],
        ),
        throwsViolation(
          'Expected only one target for this versioning strategy',
        ),
      );
    });

    test('throws error when version is bumped down', () {
      expect(
        () => Version.parse(version).modifyVersion(
          BumpType.down,
          versionTargets: ['major'],
        ),
        throwsViolation(
          'This versioning strategy does not allow bumping down versions',
        ),
      );
    });
  });

  group('absolute versioning strategy', () {
    test('bumps up/down the major version', () {
      const expectedBumpedVersion = '11.10.10-prerelease+21';
      const expectedDumpedVersion = '9.10.10-prerelease+21';

      final bumpedVersion = Version.parse(version).modifyVersion(
        BumpType.up,
        versionTargets: ['major'],
        strategy: ModifyStrategy.absolute,
      );

      final dumpedVersion = Version.parse(version).modifyVersion(
        BumpType.down,
        versionTargets: ['major'],
        strategy: ModifyStrategy.absolute,
      );

      expect(bumpedVersion, expectedBumpedVersion);
      expect(dumpedVersion, expectedDumpedVersion);
    });

    test('bumps up/down minor version', () {
      const expectedBumpedVersion = '10.11.10-prerelease+21';
      const expectedDumpedVersion = '10.9.10-prerelease+21';

      final bumpedVersion = Version.parse(version).modifyVersion(
        BumpType.up,
        versionTargets: ['minor'],
        strategy: ModifyStrategy.absolute,
      );

      final dumpedVersion = Version.parse(version).modifyVersion(
        BumpType.down,
        versionTargets: ['minor'],
        strategy: ModifyStrategy.absolute,
      );

      expect(bumpedVersion, expectedBumpedVersion);
      expect(dumpedVersion, expectedDumpedVersion);
    });

    test('bumps up/down patch version', () {
      const expectedBumpedVersion = '10.10.11-prerelease+21';
      const expectedDumpedVersion = '10.10.9-prerelease+21';

      final bumpedVersion = Version.parse(version).modifyVersion(
        BumpType.up,
        versionTargets: ['patch'],
        strategy: ModifyStrategy.absolute,
      );

      final dumpedVersion = Version.parse(version).modifyVersion(
        BumpType.down,
        versionTargets: ['patch'],
        strategy: ModifyStrategy.absolute,
      );

      expect(bumpedVersion, expectedBumpedVersion);
      expect(dumpedVersion, expectedDumpedVersion);
    });

    test('bumps up/down build number', () {
      const expectedBumpedVersion = '10.10.10-prerelease+22';
      const expectedDumpedVersion = '10.10.10-prerelease+20';

      final bumpedVersion = Version.parse(version).modifyVersion(
        BumpType.up,
        versionTargets: ['build-number'],
        strategy: ModifyStrategy.absolute,
      );

      final dumpedVersion = Version.parse(version).modifyVersion(
        BumpType.down,
        versionTargets: ['build-number'],
        strategy: ModifyStrategy.absolute,
      );

      expect(bumpedVersion, expectedBumpedVersion);
      expect(dumpedVersion, expectedDumpedVersion);
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

      final isSame = const MapEquality<String, int>().equals(
        map,
        {'major': 10, 'minor': 10, 'patch': 10},
      );

      expect(isSame, true);
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
  });
}
