import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
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

  group('preps modify commands args', () {
    test('preps args', () {
      final args = <String>['bump', 'major'];

      final prepData = normalizer.prepArgs(args);

      expect(prepData.action, 'bump');
      expect(listEquality.equals(['major'], prepData.versionTargets), true);
      expect(prepData.strategy, ModifyStrategy.relative);
      expect(prepData.requestPath, false);
    });

    test('preps args and sets request path to true', () {
      final args = <String>['bump', 'major', 'with-path'];

      final prepData = normalizer.prepArgs(args);

      expect(prepData.action, 'bump');
      expect(listEquality.equals(['major'], prepData.versionTargets), true);
      expect(prepData.strategy, ModifyStrategy.relative);
      expect(prepData.requestPath, true);
    });

    test('preps args and sets request path & absolute version to true', () {
      final args = <String>['bump', 'major', 'with-path', 'absolute'];

      final prepData = normalizer.prepArgs(args);

      expect(prepData.action, 'bump');
      expect(listEquality.equals(['major'], prepData.versionTargets), true);
      expect(prepData.strategy, ModifyStrategy.absolute);
      expect(prepData.requestPath, true);
    });
  });

  group('preps change command args', () {
    test('preps args', () {
      final args = <String>['name=Test', 'version=1.1.1'];

      final prepped = args.fold(
        <String, String>{},
        (previousValue, element) {
          final split = element.split('=');
          previousValue.addAll({split.first: split.last});
          return previousValue;
        },
      );

      final argsAndValues = normalizer.getArgAndValues(args);

      expect(
        listEquality.equals(argsAndValues.keys.toList(), prepped.keys.toList()),
        true,
      );
      expect(
        listEquality.equals(
          argsAndValues.values.toList(),
          prepped.values.toList(),
        ),
        true,
      );
    });
  });
}
