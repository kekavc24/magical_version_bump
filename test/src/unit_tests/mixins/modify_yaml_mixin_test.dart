import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
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
    test('bumps up only major version', () async {
      const bumpedVersion = '12.11.11';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        version,
        versionTargets: majorTarget,
        strategy: ModifyStrategy.absolute,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('bumps up only minor version', () async {
      const bumpedVersion = '11.12.11';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        version,
        versionTargets: minorTarget,
        strategy: ModifyStrategy.absolute,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('bumps up only patch version', () async {
      const bumpedVersion = '11.11.12';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        version,
        versionTargets: patchTarget,
        strategy: ModifyStrategy.absolute,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('bumps up only build number', () async {
      const bumpedVersion = '11.11.11+12';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        versionWithBuild,
        versionTargets: buildTarget,
        strategy: ModifyStrategy.absolute,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('appends and bumps up only build number', () async {
      const bumpedVersion = '11.11.11+2';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        version,
        versionTargets: buildTarget,
        strategy: ModifyStrategy.absolute,
      );

      expect(dynamicBump.version, bumpedVersion);
    });
  });

  group('collective versioning (relative)', () {
    test('collectively bumps up major version', () async {
      const bumpedVersion = '12.0.0';

      final dynamicBump = await modifier.dynamicBump(
        version,
        versionTargets: majorTarget,
        strategy: ModifyStrategy.relative,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('collectively bumps up/down minor version', () async {
      const bumpedVersion = '11.12.0';

      final dynamicBump = await modifier.dynamicBump(
        version,
        versionTargets: minorTarget,
        strategy: ModifyStrategy.relative,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('collectively bumps up/down patch version', () async {
      const bumpedVersion = '11.11.12';

      final dynamicBump = await modifier.dynamicBump(
        version,
        versionTargets: patchTarget,
        strategy: ModifyStrategy.relative,
      );

      expect(dynamicBump.version, bumpedVersion);
    });

    test('throws error when more than one targets are added', () async {
      final future = modifier.dynamicBump(
        version,
        versionTargets: [...majorTarget, ...patchTarget, ...buildTarget],
        strategy: ModifyStrategy.relative,
      );

      expect(
        () async => future,
        throwsViolation(
          'Expected only one target for this versioning strategy',
        ),
      );
    });
  });

  group('modifies yaml nodes correctly', () {
    test('modifies name correctly', () async {
      const node = 'name';
      const changes = 'Test File Passed';

      final moddedFile = await modifier.editYamlFile(fakeYaml, node, changes);

      final nodeValue = getNodeValue(moddedFile, node);

      expect(nodeValue, changes);
    });

    test('modifies description correctly', () async {
      const node = 'description';
      const changes = 'This is a test that passed';

      final moddedFile = await modifier.editYamlFile(fakeYaml, node, changes);

      final nodeValue = getNodeValue(moddedFile, node);

      expect(nodeValue, changes);
    });

    test('modifies version correctly', () async {
      const node = 'version';
      const changes = '12.12.12';

      final moddedFile = await modifier.editYamlFile(fakeYaml, node, changes);

      final nodeValue = getNodeValue(moddedFile, node);

      expect(nodeValue, changes);
    });

    test('modifies homepage url correctly', () async {
      const node = 'homepage';
      const changes = 'https://url.to.passed-test-for-homepage';

      final moddedFile = await modifier.editYamlFile(fakeYaml, node, changes);

      final nodeValue = getNodeValue(moddedFile, node);

      expect(nodeValue, changes);
    });

    test('modifies repository url correctly', () async {
      const node = 'repository';
      const changes = 'https://url.to.passed-test-for-repository';

      final moddedFile = await modifier.editYamlFile(fakeYaml, node, changes);

      final nodeValue = getNodeValue(moddedFile, node);

      expect(nodeValue, changes);
    });

    test('modifies issue_tracker url correctly', () async {
      const node = 'issue_tracker';
      const changes = 'https://url.to.passed-test-for-issue-tracker';

      final moddedFile = await modifier.editYamlFile(fakeYaml, node, changes);

      final nodeValue = getNodeValue(moddedFile, node);

      expect(nodeValue, changes);
    });

    test('modifies documentation correctly', () async {
      const node = 'documentation';
      const changes = 'https://url.to.passed-test-for-documentation';

      final moddedFile = await modifier.editYamlFile(fakeYaml, node, changes);

      final nodeValue = getNodeValue(moddedFile, node);

      expect(nodeValue, changes);
    });
  });
}
