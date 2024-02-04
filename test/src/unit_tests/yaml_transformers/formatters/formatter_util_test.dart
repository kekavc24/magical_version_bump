import 'package:magical_version_bump/src/core/yaml_transformers/formatter/formatter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/tracker.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

typedef _ListOfKeys = List<TrackerKey<String>>;

void main() {
  group('util extractors based on Origin', () {
    test('returns single key when Origin.value', () {
      final key = extractKey<TrackerKey<String>>(
        origin: Origin.value,
        value: 'value',
      );

      const expectedKey = TrackerKey<String>.fromValue('value', Origin.value);

      expect(key, equals(expectedKey));
    });

    test(
      'throws an error when Origin.value and single key is not a string',
      () {
        expect(
          () => extractKey<TrackerKey<String>>(
            origin: Origin.value,
            value: ['value'],
          ),
          throwsA(isA<TypeError>()),
        );
      },
    );

    test('returns a list of keys when Origin.key', () {
      final viableKeys = ['key', 'otherKey'];

      final keys = extractKey<_ListOfKeys>(
        origin: Origin.key,
        value: viableKeys,
      );

      final expectedKeys = viableKeys.map(
        (e) => TrackerKey(key: e, origin: Origin.key),
      );

      expect(keys, equals(expectedKeys));
    });

    test('returns a list of keys when Origin.pair', () {
      final pairs = {
        'key': 'value',
        'otherKey': 'value',
      };

      final keys = extractKey<_ListOfKeys>(
        origin: Origin.pair,
        value: pairs,
      );

      final expectedKeys = pairs.entries.map(
        (e) => DualTrackerKey<String, String>.fromEntry(entry: e),
      );

      expect(keys, equals(expectedKeys));
    });
  });

  group('util extractors based on MatchedNodeData', () {
    test('returns a list of all possible keys', () {
      final node = NodeData.stringSkeleton(
        path: const ['root'],
        key: 'key',
        value: 'value',
      );

      final match = MatchedNodeData.fromFinder(
        nodeData: node,
        matchedKeys: const ['key'],
        matchedValue: 'value',
        matchedPairs: const {'root': 'key'},
      );

      final keys = getKeysFromMatch(match);

      const expectedKeys = [
        TrackerKey<String>.fromValue('value', Origin.value),
        TrackerKey<String>.fromValue('key', Origin.key),
        DualTrackerKey<String, String>.fromValue(key: 'root', otherKey: 'key'),
      ];

      expect(keys, equals(expectedKeys));
    });
  });

  group('util match wrappers', () {
    test(
      'wrap matches with green ANSI code for matching values in path',
      () {
        const path = 'test/matches/in/path';

        final matches = ['matches', 'path'];

        final expectedPath =
            "test/${matchColor.wrap('matches')}/in/${matchColor.wrap('path')}";

        final wrappedPath = wrapMatches(path: path, matches: matches);

        expect(wrappedPath.path, expectedPath);
      },
    );

    test(
      'wraps keys matched with green ANSI code & replaced keys with red',
      () {
        const defaultPath = 'key/value';

        final replacements = {'key': 'updatedKey'};

        final oldPathWithTarget = "${replacedColor.wrap('key')}/value";
        final updatedPath = "${matchColor.wrap('updatedKey')}/value";

        final pathInfo = replaceAndWrap(
          path: defaultPath,
          replacedKeys: true,
          replacements: replacements,
        );

        expect(pathInfo.path, equals(oldPathWithTarget));
        expect(pathInfo.updatedPath, equals(updatedPath));
      },
    );

    test(
      'wraps values matched with green ANSI code & replaced keys with red',
      () {
        const defaultPath = 'key/value';

        final replacements = {'value': 'updatedValue'};

        final oldPathWithTarget = "key/${replacedColor.wrap('value')}";
        final updatedPath = "key/${matchColor.wrap('updatedValue')}";

        final pathInfo = replaceAndWrap(
          path: defaultPath,
          replacedKeys: false,
          replacements: replacements,
        );

        expect(pathInfo.path, equals(oldPathWithTarget));
        expect(pathInfo.updatedPath, equals(updatedPath));
      },
    );
  });

  group('util tree-builder', () {
    test('returns custom separators based on CharSet', () {
      expect(getChildSeparator(), equals(branchColor.wrap('│')));
      expect(
        getChildSeparator(charSet: CharSet.ascii),
        equals(branchColor.wrap('|')),
      );
    });

    test('returns custom count separator based on CharSet', () {
      expect(getCountSeparator(), equals('──'));
      expect(getCountSeparator(charSet: CharSet.ascii), '--');
    });

    test('returns valid branch based on CharSet and position', () {
      final lastChildUtf8 = branchColor.wrap('└──');
      final lastChildAscii = branchColor.wrap('`--');

      final branchUtf8 = branchColor.wrap('├──');
      final branchAscii = branchColor.wrap('|--');

      expect(getBranch(), equals(branchUtf8));
      expect(getBranch(charSet: CharSet.ascii), equals(branchAscii));

      expect(getBranch(isLastChild: true), equals(lastChildUtf8));
      expect(
        getBranch(charSet: CharSet.ascii, isLastChild: true),
        equals(lastChildAscii),
      );
    });

    test('returns valid header for a file', () {
      const file = 'test.file';

      final infoForFinder =
          '''Aggregated Info for ${styleItalic.wrap(file)} : Found 1 matches''';
      final infoForReplacer = '$infoForFinder, Replaced 1';

      expect(
        createHeader(
          isReplaceMode: false,
          fileName: file,
          countOfMatches: 1,
          countOfReplacements: null,
        ),
        equalsIgnoringWhitespace('** $infoForFinder **'),
      );

      expect(
        createHeader(
          isReplaceMode: true,
          fileName: file,
          countOfMatches: 1,
          countOfReplacements: 1,
        ),
        equalsIgnoringWhitespace('** $infoForReplacer **'),
      );
    });

    test('returns valid tree for single paths', () {
      const match = 'key';
      const path = 'my/path';

      const tree = '''
        $match ── Found 1
        └── $path
        ''';

      expect(
        formatInfo(
          isReplaceMode: false,
          key: match,
          formattedPaths: const [
            (path: path, updatedPath: null),
          ],
        ),
        equalsIgnoringWhitespace(tree),
      );
    });

    test('returns valid tree for dual paths in replace mode', () {
      const match = 'key';
      const path = 'my/path';

      const tree = '''
        $match ── Replaced 1
        ├── $path
        └── $path
        ''';

      expect(
        formatInfo(
          isReplaceMode: true,
          key: match,
          formattedPaths: const [
            (path: path, updatedPath: path),
          ],
        ),
        equalsIgnoringWhitespace(tree),
      );
    });
  });
}
