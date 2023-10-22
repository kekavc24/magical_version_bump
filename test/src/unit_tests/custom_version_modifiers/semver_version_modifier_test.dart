import 'package:magical_version_bump/src/core/custom_version_modifiers/semver_version_modifer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

void main() {
  const versionFromFile = '0.0.0-alpha+0';
  const version = '10.10.10-prerelease+21';
  const versionWithCustomBuild = '8.8.8+MagicalVersionBump';

  group('add presets', () {
    test('returns version as is when preset is not set', () {
      final modifier = TestVersionModifier.forTest().copyWith(
        presetType: PresetType.none,
      );

      final versionFromPreset = MagicalSEMVER.addPresets(
        versionFromFile,
        modifiers: modifier,
      );

      expect(versionFromPreset, versionFromFile);
    });

    test('returns preset version when only version is preset', () {
      final modifier = TestVersionModifier.forTest().copyWith(
        presetType: PresetType.version,
        version: '1.0.0',
      );

      final versionFromPreset = MagicalSEMVER.addPresets(
        versionFromFile,
        modifiers: modifier,
      );

      expect(versionFromPreset, '1.0.0');
    });

    test('returns empty string when preset version is null', () {
      final modifier = TestVersionModifier.forTest().copyWith(
        presetType: PresetType.version,
      );

      final versionFromPreset = MagicalSEMVER.addPresets(
        versionFromFile,
        modifiers: modifier,
      );

      expect(versionFromPreset, isEmpty);
    });

    test('returns modified version when all values are preset', () {
      final modifier = TestVersionModifier.forTest().copyWith(
        presetType: PresetType.all,
        version: '1.0.0',
        prerelease: 'production',
        build: '1',
      );

      final versionFromPreset = MagicalSEMVER.addPresets(
        versionFromFile,
        modifiers: modifier,
      );

      expect(versionFromPreset, '1.0.0-production+1');
    });

    test('returns modified version, preserves prerelease & build info', () {
      final modifier = TestVersionModifier.forTest().copyWith(
        presetType: PresetType.all,
        version: '1.0.0',
        keepBuild: true,
        keepPre: true,
      );

      final versionFromPreset = MagicalSEMVER.addPresets(
        versionFromFile,
        modifiers: modifier,
      );

      expect(versionFromPreset, '1.0.0-alpha+0');
    });

    test(
      'returns modified version, sets new prerelease and keeps build-number',
      () {
        final modifier = TestVersionModifier.forTest().copyWith(
          presetType: PresetType.all,
          version: '1.0.0',
          prerelease: 'production',
          keepBuild: true,
        );

        final versionFromPreset = MagicalSEMVER.addPresets(
          versionFromFile,
          modifiers: modifier,
        );

        expect(versionFromPreset, '1.0.0-production+0');
      },
    );

    test(
      'returns modified version, sets new build-number and keeps prerelease',
      () {
        final modifier = TestVersionModifier.forTest().copyWith(
          presetType: PresetType.all,
          version: '1.0.0',
          keepPre: true,
          build: '1',
        );

        final versionFromPreset = MagicalSEMVER.addPresets(
          versionFromFile,
          modifiers: modifier,
        );

        expect(versionFromPreset, '1.0.0-alpha+1');
      },
    );
  });

  group('add final touches', () {
    test('returns version as is when version info was preset', () {
      final modifier = TestVersionModifier.forTest().copyWith(
        presetType: PresetType.all,
      );

      final completeVersion = MagicalSEMVER.appendPreAndBuild(
        versionFromFile,
        modifiers: modifier,
      );

      expect(completeVersion, versionFromFile);
    });

    test(
      '''returns version as is when prerelease & build are null and never preset''',
      () {
        final modifier = TestVersionModifier.forTest().copyWith(
          presetType: PresetType.none,
        );

        final completeVersion = MagicalSEMVER.appendPreAndBuild(
          versionFromFile,
          modifiers: modifier,
        );

        expect(completeVersion, versionFromFile);
      },
    );

    test('returns version with updated prerelease & build info', () {
      final modifier = TestVersionModifier.forTest().copyWith(
        presetType: PresetType.none,
        prerelease: 'production',
        build: '1',
      );

      final completeVersion = MagicalSEMVER.appendPreAndBuild(
        versionFromFile,
        modifiers: modifier,
      );

      expect(completeVersion, '0.0.0-production+1');
    });
  });

  group('relative versioning strategy', () {
    test('bumps major version', () {
      const expectedBumpedVersion = '11.0.0+21';

      final bumpedVersion = MagicalSEMVER.bumpVersion(
        version,
        versionTargets: ['major'],
        strategy: ModifyStrategy.relative,
      );

      expect(bumpedVersion.version, expectedBumpedVersion);
    });

    test('bumps minor version', () {
      const expectedBumpedVersion = '10.11.0+21';

      final bumpedVersion = MagicalSEMVER.bumpVersion(
        version,
        versionTargets: ['minor'],
        strategy: ModifyStrategy.relative,
      );

      expect(bumpedVersion.version, expectedBumpedVersion);
    });

    test('bumps patch version', () {
      const expectedBumpedVersion = '10.10.10+21';

      final bumpedVersion = MagicalSEMVER.bumpVersion(
        version,
        versionTargets: ['patch'],
        strategy: ModifyStrategy.relative,
      );

      expect(bumpedVersion.version, expectedBumpedVersion);
    });

    test('bumps build number', () {
      const expectedBumpedVersion = '10.10.10-prerelease+22';

      final bumpedVersion = MagicalSEMVER.bumpVersion(
        version,
        versionTargets: ['build-number'],
        strategy: ModifyStrategy.relative,
      );

      expect(bumpedVersion.version, expectedBumpedVersion);
    });

    test('ignores custom build numbers', () {
      final bumpedVersion = MagicalSEMVER.bumpVersion(
        versionWithCustomBuild,
        versionTargets: ['build-number'],
        strategy: ModifyStrategy.relative,
      );

      expect(bumpedVersion.version, versionWithCustomBuild);
    });

    test('throws error if more than one target is passed in', () {
      expect(
        () => MagicalSEMVER.bumpVersion(
          version,
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

      final bumpedVersion = MagicalSEMVER.bumpVersion(
        version,
        versionTargets: ['major'],
        strategy: ModifyStrategy.absolute,
      );

      expect(bumpedVersion.version, expectedBumpedVersion);
    });

    test('bumps up minor version', () {
      const expectedBumpedVersion = '10.11.10-prerelease+21';

      final bumpedVersion = MagicalSEMVER.bumpVersion(
        version,
        versionTargets: ['minor'],
        strategy: ModifyStrategy.absolute,
      );

      expect(bumpedVersion.version, expectedBumpedVersion);
    });

    test('bumps up patch version', () {
      const expectedBumpedVersion = '10.10.11-prerelease+21';

      final bumpedVersion = MagicalSEMVER.bumpVersion(
        version,
        versionTargets: ['patch'],
        strategy: ModifyStrategy.absolute,
      );

      expect(bumpedVersion.version, expectedBumpedVersion);
    });

    test('bumps up build number', () {
      const expectedBumpedVersion = '10.10.10-prerelease+22';

      final bumpedVersion = MagicalSEMVER.bumpVersion(
        version,
        versionTargets: ['build-number'],
        strategy: ModifyStrategy.absolute,
      );

      expect(bumpedVersion.version, expectedBumpedVersion);
    });

    test('ignores custom build numbers', () {
      final bumpedVersion = MagicalSEMVER.bumpVersion(
        versionWithCustomBuild,
        versionTargets: ['build-number'],
        strategy: ModifyStrategy.absolute,
      );

      expect(bumpedVersion.version, versionWithCustomBuild);
    });
  });
}
