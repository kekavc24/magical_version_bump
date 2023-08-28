import 'package:args/args.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:test/test.dart';

class _FakeNormalizer with NormalizeArgs {}

void main() {
  late _FakeNormalizer normalizer;
  late ArgParser argParser;

  const directory = 'gym';

  const version = '10.10.10';
  const prerelease = 'spring-before-summer';
  const build = 'muscular';

  final modifierArgs = <String>[
    '--preset',
    '--set-version',
    version,
    '--set-prerelease',
    prerelease,
    '--set-build',
    build,
  ];

  setUp(() {
    normalizer = _FakeNormalizer();
    argParser = ArgParser()
      ..addFlag(
        'request-path',
      )
      ..addOption(
        'directory',
      )
      ..addFlag(
        'preset',
      )
      ..addOption(
        'set-version',
      )
      ..addOption(
        'set-prerelease',
      )
      ..addOption(
        'set-build',
      )
      ..addFlag(
        'keep-pre',
      )
      ..addFlag(
        'keep-build',
      );
  });

  group('modifiers', () {
    test('returns path and whether to request path', () {
      final argResults = argParser.parse(
        ['--request-path', '--directory', directory],
      );

      final checkedPath = normalizer.checkPath(argResults);

      expect(checkedPath.requestPath, true);
      expect(checkedPath.path, directory);
    });

    test(
      'return correct version modifiers, discards old prerelease & build',
      () {
        final argResults = argParser.parse(modifierArgs);

        final versionModifiers = normalizer.checkForVersionModifiers(
          argResults,
          checkPreset: true,
        );

        expect(versionModifiers.preset, true);
        expect(versionModifiers.presetOnlyVersion, false);
        expect(versionModifiers.version, version);
        expect(versionModifiers.prerelease, prerelease);
        expect(versionModifiers.build, build);
        expect(versionModifiers.keepPre, false);
        expect(versionModifiers.keepBuild, false);
      },
    );

    test(
      'return correct version modifiers, retains old prerelease & build',
      () {
        final argResults = argParser.parse(
          [...modifierArgs, '--keep-pre', '--keep-build'],
        );

        final versionModifiers = normalizer.checkForVersionModifiers(
          argResults,
          checkPreset: true,
        );

        expect(versionModifiers.preset, true);
        expect(versionModifiers.presetOnlyVersion, false);
        expect(versionModifiers.version, version);
        expect(versionModifiers.prerelease, prerelease);
        expect(versionModifiers.build, build);
        expect(versionModifiers.keepPre, true);
        expect(versionModifiers.keepBuild, true);
      },
    );

    test(
      'returns correct version modifiers, never checks for preset',
      () {
        final argResults = argParser.parse(modifierArgs);

        final versionModifiers = normalizer.checkForVersionModifiers(
          argResults,
          checkPreset: false,
        );

        expect(versionModifiers.preset, false);
        expect(versionModifiers.presetOnlyVersion, true);
        expect(versionModifiers.version, version);
        expect(versionModifiers.prerelease, prerelease);
        expect(versionModifiers.build, build);
        expect(versionModifiers.keepPre, false);
        expect(versionModifiers.keepBuild, false);
      },
    );
  });
}
