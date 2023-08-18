import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/core/mixins/command_mixins.dart';
import 'package:test/test.dart';

class _FakeNormalizer with NormalizeArgs {}

void main() {
  late _FakeNormalizer normalizer;
  late ListEquality<String> listEquality;

  setUp(() {
    normalizer = _FakeNormalizer();
    listEquality = const ListEquality<String>();
  });

  group('normalizes flags correctly', () {
    test("removes the '--' & '-' appended to flags with no set path", () {
      final flags = <String>['--double-fake-flag', '-single-fake-flag'];
      final sanitizedFlags = <String>['double-fake-flag', 'single-fake-flag'];

      final normalizedFlags = normalizer.normalizeArgs(flags);

      final wasNormalized = listEquality.equals(
        normalizedFlags,
        sanitizedFlags,
      );

      expect(wasNormalized, true);
    });

    test('gets all setter options in args', () {
      final args = <String>[
        'myArg',
        'set-path=path',
        'set-build=build',
        'set-prerelease=prerelease',
        'set-version=1.0.0',
        'keep-pre',
        'keep-build',
        'preset',
      ];

      final checkedSetters = normalizer.checkForSetters(args);

      expect(listEquality.equals(checkedSetters.args, ['myArg']), true);
      expect(checkedSetters.path, 'path');
      expect(checkedSetters.build, 'build');
      expect(checkedSetters.prerelease, 'prerelease');
      expect(checkedSetters.version, '1.0.0');
      expect(checkedSetters.keepBuild, true);
      expect(checkedSetters.keepPre, true);
      expect(checkedSetters.preset, true);
    });

    test('returns preset as false and preset-version as true', () {
      final args = <String>[
        'myArg',
        'set-version=1.0.0',
      ];

      final checkedSetters = normalizer.checkForSetters(args);

      expect(listEquality.equals(checkedSetters.args, ['myArg']), true);
      expect(checkedSetters.version, '1.0.0');
      expect(checkedSetters.preset, false);
      expect(checkedSetters.presetOnlyVersion, true);
    });
  });
}
