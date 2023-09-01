import 'package:args/args.dart';
import 'package:magical_version_bump/src/utils/mixins/command_mixins.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

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

  group('dictionary', () {
    test('extracts key and value', () {
      final dictionary = normalizer.extractDictionary(
        'testKey=testValue',
        append: false,
      );

      expect(dictionary.rootKeys, equals(['testKey']));
      expect(dictionary.data is String, true);
      expect(dictionary.data, 'testValue');
    });

    test('extracts multiple keys and value', () {
      final dictionary = normalizer.extractDictionary(
        'testKey|anotherKey=testValue',
        append: false,
      );

      expect(dictionary.rootKeys, equals(['testKey', 'anotherKey']));
      expect(dictionary.data is String, true);
      expect(dictionary.data, 'testValue');
    });

    test('extracts key and multiple values', () {
      final dictionary = normalizer.extractDictionary(
        'testKey=testValue,anotherValue',
        append: false,
      );

      expect(dictionary.rootKeys, equals(['testKey']));
      expect(dictionary.data is List<String>, true);
      expect(dictionary.data, equals(['testValue', 'anotherValue']));
    });

    test('extracts key and multiple values, retains non-empty', () {
      final dictionary = normalizer.extractDictionary(
        'testKey=testValue,anotherValue,',
        append: false,
      );

      expect(dictionary.rootKeys, equals(['testKey']));
      expect(dictionary.data is List<String>, true);
      expect(dictionary.data, equals(['testValue', 'anotherValue']));
    });

    test('extracts multiple keys and values', () {
      final dictionary = normalizer.extractDictionary(
        'testKey|anotherKey=testValue,anotherValue',
        append: false,
      );

      expect(dictionary.rootKeys, equals(['testKey', 'anotherKey']));
      expect(dictionary.data is List<String>, true);
      expect(dictionary.data, equals(['testValue', 'anotherValue']));
    });

    test('extracts key and mapped values', () {
      final dictionary = normalizer.extractDictionary(
        'testKey=testMapKey:testMapValue',
        append: false,
      );

      expect(dictionary.rootKeys, equals(['testKey']));
      expect(dictionary.data is Map<String, String>, true);
      expect(
        dictionary.data,
        equals({'testMapKey': 'testMapValue'}),
      );
    });

    test('extracts key and mapped values, sets empty pairs to null', () {
      final dictionary = normalizer.extractDictionary(
        'testKey=testMapKey:',
        append: false,
      );

      expect(dictionary.rootKeys, equals(['testKey']));
      expect(dictionary.data is Map<String, String>, true);
      expect(
        dictionary.data,
        equals({'testMapKey': 'null'}),
      );
    });

    test('extracts multiple keys and mapped values', () {
      final dictionary = normalizer.extractDictionary(
        'testKey|anotherKey=testMapKey:testMapValue,otherMapKey:otherMapValue',
        append: false,
      );

      final expectedMappedValues = <String, String>{
        'testMapKey': 'testMapValue',
        'otherMapKey': 'otherMapValue',
      };

      expect(dictionary.rootKeys, equals(['testKey', 'anotherKey']));
      expect(dictionary.data is Map<String, String>, true);
      expect(dictionary.data, equals(expectedMappedValues));
    });
  });

  test('throws error when parsed value is empty', () {
    expect(
      () => normalizer.extractDictionary('', append: false),
      throwsViolation('The root key cannot be empty/null'),
    );
  });

  test('throws error when parsed value has no key-value pair', () {
    const valueWithOnePair = 'key=';
    const valueWithBlanks = '=';

    expect(
      () => normalizer.extractDictionary(
        valueWithBlanks,
        append: false,
      ),
      throwsViolation(
        'Invalid keys and value pair at "$valueWithBlanks"',
      ),
    );

    expect(
      () => normalizer.extractDictionary(
        valueWithOnePair,
        append: false,
      ),
      throwsViolation(
        'Invalid keys and value pair at "$valueWithOnePair"',
      ),
    );
  });

  test('throws error when parsed value has non-uniform formats', () {
    const nonUniformValue = 'key=value,mapKey:mapValue';

    expect(
      () => normalizer.extractDictionary(
        nonUniformValue,
        append: false,
      ),
      throwsViolation('Mixed format at $nonUniformValue'),
    );
  });
}
