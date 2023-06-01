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
        normalizedFlags.args,
        sanitizedFlags,
      );

      expect(wasNormalized, true);
      expect(normalizedFlags.hasPath, false);
      expect(normalizedFlags.setPath, isNull);
    });

    test("removes the '--' & '-' appended to flags with set path", () {
      final flags = <String>[
        '--double-fake-flag',
        '-single-fake-flag',
        '--set-path=myPath'
      ];
      final sanitizedFlags = <String>['double-fake-flag', 'single-fake-flag'];

      final normalizedFlags = normalizer.normalizeArgs(flags);

      final wasNormalized = listEquality.equals(
        normalizedFlags.args,
        sanitizedFlags,
      );

      expect(wasNormalized, true);
      expect(normalizedFlags.hasPath, true);
      expect(normalizedFlags.setPath, 'myPath');
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
