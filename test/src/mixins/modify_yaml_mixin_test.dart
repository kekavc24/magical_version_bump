import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:test/test.dart';

import '../../helpers/helpers.dart';

class _FakeYamlModifier with ModifyYaml {}

void main() {
  late _FakeYamlModifier modifier;
  late ListEquality<String> listEquality;

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
    listEquality = const ListEquality<String>();
  });

  group('get versions correctly', () {
    test('returns correct index', () {
      const majorIndex = 0;
      const minorIndex = 1;
      const patchOrBuildIndex = 2;

      final indexOfMajor = modifier.checkIndex(majorTarget.first);
      final indexOfMinor = modifier.checkIndex(minorTarget.first);
      final indexOfPatch = modifier.checkIndex(patchTarget.first);
      final indexOfBuild = modifier.checkIndex(buildTarget.first);

      expect(indexOfMajor, majorIndex);
      expect(indexOfMinor, minorIndex);
      expect(indexOfPatch, patchOrBuildIndex);
      expect(indexOfBuild, patchOrBuildIndex);
    });

    test('return version separated correctly', () {
      final correctSplit = version.split('.');
      final correctSplitWithBuild = versionWithBuild.split('.');

      final split = modifier.getVersions(version, []);
      final splitWithBuild = modifier.getVersions(versionWithBuild, []);

      final matchesSplit = listEquality.equals(
        split,
        correctSplit,
      );
      final matchesSplitWithBuild = listEquality.equals(
        splitWithBuild,
        correctSplitWithBuild,
      );

      expect(matchesSplit, true);
      expect(matchesSplitWithBuild, true);
    });

    test('appends missing version and returns versions', () {
      const incorrectVersion = '1';
      final correctVersions = '1.0.0'.split('.');

      final versions = modifier.getVersions(
        incorrectVersion,
        [...patchTarget, ...minorTarget],
      );

      final wasAppended = listEquality.equals(
        versions,
        correctVersions,
      );

      expect(wasAppended, true);
    });

    test('appends missing build number and returns versions', () {
      final appendedVersions = '$version+1'.split('.');

      final versions = modifier.getVersions(
        version,
        buildTarget,
      );

      final wasAppended = listEquality.equals(
        versions,
        appendedVersions,
      );

      expect(wasAppended, true);
    });
  });

  group('independent versioning (absolute)', () {
    test('bumps up/down only major version', () async {
      const bumpedVersion = '12.11.11';
      const dumpedVersion = '10.11.11';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        'bump',
        majorTarget,
        version,
        absoluteVersioning: true,
      );

      // Bump down version by 1
      final dynamicDump = await modifier.dynamicBump(
        'dump',
        majorTarget,
        version,
        absoluteVersioning: true,
      );

      expect(dynamicBump, bumpedVersion);
      expect(dynamicDump, dumpedVersion);
    });

    test('bumps up/down only minor version', () async {
      const bumpedVersion = '11.12.11';
      const dumpedVersion = '11.10.11';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        'bump',
        minorTarget,
        version,
        absoluteVersioning: true,
      );

      // Bump down version by 1
      final dynamicDump = await modifier.dynamicBump(
        'dump',
        minorTarget,
        version,
        absoluteVersioning: true,
      );

      expect(dynamicBump, bumpedVersion);
      expect(dynamicDump, dumpedVersion);
    });

    test('bumps up/down only patch version', () async {
      const bumpedVersion = '11.11.12';
      const dumpedVersion = '11.11.10';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        'bump',
        patchTarget,
        version,
        absoluteVersioning: true,
      );

      // Bump down version by 1
      final dynamicDump = await modifier.dynamicBump(
        'dump',
        patchTarget,
        version,
        absoluteVersioning: true,
      );

      expect(dynamicBump, bumpedVersion);
      expect(dynamicDump, dumpedVersion);
    });

    test('bumps up/down only build number', () async {
      const bumpedVersion = '11.11.11+12';
      const dumpedVersion = '11.11.11+10';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        'bump',
        buildTarget,
        versionWithBuild,
        absoluteVersioning: true,
      );

      // Bump down version by 1
      final dynamicDump = await modifier.dynamicBump(
        'dump',
        buildTarget,
        versionWithBuild,
        absoluteVersioning: true,
      );

      expect(dynamicBump, bumpedVersion);
      expect(dynamicDump, dumpedVersion);
    });

    test('appends and bumps up/down only build number', () async {
      const bumpedVersion = '11.11.11+2';
      const dumpedVersion = '11.11.11+0';

      // Bump up version by 1
      final dynamicBump = await modifier.dynamicBump(
        'bump',
        buildTarget,
        version,
        absoluteVersioning: true,
      );

      // Bump down version by 1
      final dynamicDump = await modifier.dynamicBump(
        'dump',
        buildTarget,
        version,
        absoluteVersioning: true,
      );

      expect(dynamicBump, bumpedVersion);
      expect(dynamicDump, dumpedVersion);
    });
  });

  group('collective versioning (relative)', () {
    test('collectively bumps up/down major version', () async {
      const bumpedVersion = '12.0.0';
      const dumpedVersion = '10.0.0';

      final dynamicBump = await modifier.dynamicBump(
        'bump',
        majorTarget,
        version,
      );

      // Bump down version by 1
      final dynamicDump = await modifier.dynamicBump(
        'dump',
        majorTarget,
        version,
      );

      expect(dynamicBump, bumpedVersion);
      expect(dynamicDump, dumpedVersion);
    });

    test('collectively bumps up/down minor version', () async {
      const bumpedVersion = '11.12.0';
      const dumpedVersion = '11.10.0';

      final dynamicBump = await modifier.dynamicBump(
        'bump',
        minorTarget,
        version,
      );

      // Bump down version by 1
      final dynamicDump = await modifier.dynamicBump(
        'dump',
        minorTarget,
        version,
      );

      expect(dynamicBump, bumpedVersion);
      expect(dynamicDump, dumpedVersion);
    });

    test('collectively bumps up/down patch version', () async {
      const bumpedVersion = '11.11.12';
      const dumpedVersion = '11.11.10';

      final dynamicBump = await modifier.dynamicBump(
        'bump',
        patchTarget,
        version,
      );

      // Bump down version by 1
      final dynamicDump = await modifier.dynamicBump(
        'dump',
        patchTarget,
        version,
      );

      expect(dynamicBump, bumpedVersion);
      expect(dynamicDump, dumpedVersion);
    });

    test('appends build number and collectively bumps up/down patch', () async {
      const bumpedVersion = '11.11.12+2';
      const dumpedVersion = '11.11.10+0';

      final dynamicBump = await modifier.dynamicBump(
        'bump',
        [...patchTarget, ...buildTarget],
        version,
      );

      // Bump down version by 1
      final dynamicDump = await modifier.dynamicBump(
        'dump',
        [...patchTarget, ...buildTarget],
        version,
      );

      expect(dynamicBump, bumpedVersion);
      expect(dynamicDump, dumpedVersion);
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
