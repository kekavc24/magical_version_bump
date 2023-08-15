import 'package:magical_version_bump/src/core/enums/enums.dart';
import 'package:magical_version_bump/src/core/mixins/command_mixins.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

class _FakeYamlModifier with ModifyYaml {}

void main() {
  late _FakeYamlModifier modifier;

  const version = '11.11.11';
  const versionWithBuild = '$version+11';

  final majorTarget = <String>['major'];
  final minorTarget = <String>['minor'];
  final patchTarget = <String>['patch'];
  final buildTarget = <String>['build-number'];

  const fakeYaml = '''
  name: Test File
  description: This is a test
  version: $version
  homepage: https://url.to.homepage
  repository: https://url.to.repository-on-github
  issue_tracker: https://url.to.issue-tracker
  documentation: https://url.to.documentation
''';

  setUp(() {
    modifier = _FakeYamlModifier();
  });

  group('independent versioning (absolute)', () {
    test('bumps up/down only major version', () async {
      const bumpedVersion = '12.11.11';
      const dumpedVersion = '10.11.11';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        version,
        action: 'bump',
        versionTargets: majorTarget,
        strategy: ModifyStrategy.absolute,
      );

      // Bump down version by 1
      final dynamicDump = await modifier.dynamicBump(
        version,
        action: 'dump',
        versionTargets: majorTarget,
        strategy: ModifyStrategy.absolute,
      );

      expect(dynamicBump.version, bumpedVersion);
      expect(dynamicDump.version, dumpedVersion);
    });

    test('bumps up/down only minor version', () async {
      const bumpedVersion = '11.12.11';
      const dumpedVersion = '11.10.11';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        version,
        action: 'bump',
        versionTargets: minorTarget,
        strategy: ModifyStrategy.absolute,
      );

      // Bump down version by 1
      final dynamicDump = await modifier.dynamicBump(
        version,
        action: 'dump',
        versionTargets: minorTarget,
        strategy: ModifyStrategy.absolute,
      );

      expect(dynamicBump.version, bumpedVersion);
      expect(dynamicDump.version, dumpedVersion);
    });

    test('bumps up/down only patch version', () async {
      const bumpedVersion = '11.11.12';
      const dumpedVersion = '11.11.10';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        version,
        action: 'bump',
        versionTargets: patchTarget,
        strategy: ModifyStrategy.absolute,
      );

      // Bump down version by 1
      final dynamicDump = await modifier.dynamicBump(
        version,
        action: 'dump',
        versionTargets: patchTarget,
        strategy: ModifyStrategy.absolute,
      );

      expect(dynamicBump.version, bumpedVersion);
      expect(dynamicDump.version, dumpedVersion);
    });

    test('bumps up/down only build number', () async {
      const bumpedVersion = '11.11.11+12';
      const dumpedVersion = '11.11.11+10';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        versionWithBuild,
        action: 'bump',
        versionTargets: buildTarget,
        strategy: ModifyStrategy.absolute,
      );

      // Bump down version by 1
      final dynamicDump = await modifier.dynamicBump(
        versionWithBuild,
        action: 'dump',
        versionTargets: buildTarget,
        strategy: ModifyStrategy.absolute,
      );
      expect(dynamicBump.version, bumpedVersion);
      expect(dynamicDump.version, dumpedVersion);
    });

    test('appends and bumps up/down only build number', () async {
      const bumpedVersion = '11.11.11+2';
      const dumpedVersion = '11.11.11+0';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        version,
        action: 'bump',
        versionTargets: buildTarget,
        strategy: ModifyStrategy.absolute,
      );

      // Bump down version by 1
      final dynamicDump = await modifier.dynamicBump(
        version,
        action: 'dump',
        versionTargets: buildTarget,
        strategy: ModifyStrategy.absolute,
      );

      expect(dynamicBump.version, bumpedVersion);
      expect(dynamicDump.version, dumpedVersion);
    });
  });

  group('collective versioning (relative)', () {
    test('collectively bumps up/down major version', () async {
      const bumpedVersion = '12.0.0';

      final dynamicBump = await modifier.dynamicBump(
        version,
        action: 'bump',
        versionTargets: majorTarget,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('collectively bumps up/down minor version', () async {
      const bumpedVersion = '11.12.0';

      final dynamicBump = await modifier.dynamicBump(
        version,
        action: 'bump',
        versionTargets: minorTarget,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('collectively bumps up/down patch version', () async {
      const bumpedVersion = '11.11.12';

      final dynamicBump = await modifier.dynamicBump(
        version,
        action: 'bump',
        versionTargets: patchTarget,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('throws error when more than one targets are added', () async {
      final future = modifier.dynamicBump(
        version,
        action: 'bump',
        versionTargets: [...majorTarget, ...patchTarget, ...buildTarget],
      );

      expect(
        () async => future,
        throwsViolation(
          'Expected only one target for this versioning strategy',
        ),
      );
    });

    test('throws error when dumping versions', () async {
      final future = modifier.dynamicBump(
        version,
        action: 'dump',
        versionTargets: [...majorTarget, ...buildTarget],
      );

      expect(
        () async => future,
        throwsViolation(
          'This versioning strategy does not allow bumping down versions',
        ),
      );
    });
  });

  group('modifies yaml nodes correctly', () {
    test('modifies name correctly', () async {
      const node = 'name';
      const changes = 'Test File Passed';

      final moddedFile = await modifier.editYamlFile(fakeYaml, node, changes);

      final nodeValue = getYamlValue(moddedFile, node);

      expect(nodeValue, changes);
    });

    test('modifies description correctly', () async {
      const node = 'description';
      const changes = 'This is a test that passed';

      final moddedFile = await modifier.editYamlFile(fakeYaml, node, changes);

      final nodeValue = getYamlValue(moddedFile, node);

      expect(nodeValue, changes);
    });

    test('modifies version correctly', () async {
      const node = 'version';
      const changes = '12.12.12';

      final moddedFile = await modifier.editYamlFile(fakeYaml, node, changes);

      final nodeValue = getYamlValue(moddedFile, node);

      expect(nodeValue, changes);
    });

    test('modifies homepage url correctly', () async {
      const node = 'homepage';
      const changes = 'https://url.to.passed-test-for-homepage';

      final moddedFile = await modifier.editYamlFile(fakeYaml, node, changes);

      final nodeValue = getYamlValue(moddedFile, node);

      expect(nodeValue, changes);
    });

    test('modifies repository url correctly', () async {
      const node = 'repository';
      const changes = 'https://url.to.passed-test-for-repository';

      final moddedFile = await modifier.editYamlFile(fakeYaml, node, changes);

      final nodeValue = getYamlValue(moddedFile, node);

      expect(nodeValue, changes);
    });

    test('modifies issue_tracker url correctly', () async {
      const node = 'issue_tracker';
      const changes = 'https://url.to.passed-test-for-issue-tracker';

      final moddedFile = await modifier.editYamlFile(fakeYaml, node, changes);

      final nodeValue = getYamlValue(moddedFile, node);

      expect(nodeValue, changes);
    });

    test('modifies documentation correctly', () async {
      const node = 'documentation';
      const changes = 'https://url.to.passed-test-for-documentation';

      final moddedFile = await modifier.editYamlFile(fakeYaml, node, changes);

      final nodeValue = getYamlValue(moddedFile, node);

      expect(nodeValue, changes);
    });
  });
}
