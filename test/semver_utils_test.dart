import 'package:checks/checks.dart';
import 'package:magical_version_bump/src/sem_ver/semver.dart';
import 'package:test/scaffolding.dart';

void main() {
  const zeroVersion = '0.0.0';

  group('Compare metadata', () {
    test('returns 0 if equal', () {
      check(compareMetadata(['test'], ['test'])).equals(0);
    });

    test('returns -1 if base metadata is less comparatively', () {
      check(compareMetadata(['pre'], ['prod'])).equals(-1);
    });

    test('returns -1 if base metadata has less metadata', () {
      check(compareMetadata(['pre'], ['prod', 'next'])).equals(-1);
    });

    test('returns 1 if base metadata is greater comparatively', () {
      check(compareMetadata(['release'], ['dev'])).equals(1);
    });

    test('returns 1 if base metadata has more metadata', () {
      check(compareMetadata(['release', 'fix'], ['dev'])).equals(1);
    });
  });

  group('Split metadata', () {
    test('extracts metadata', () {
      final meta = <dynamic>[];
      const metaString = 'test.split.meta';

      splitMetadata(
        metaString,
        callback: meta.addAll,
        exception: const FormatException('No exception'),
      );

      check(meta).deepEquals(metaString.split('.'));
    });

    test('throws exception', () {
      final meta = <dynamic>[];
      const exception = 'Wrong format!';

      check(
        () => splitMetadata(
          '*.*.*',
          callback: meta.addAll,
          exception: const FormatException(exception),
        ),
      )
          .throws<FormatException>()
          .has(
            (err) => err.message,
            'message',
          )
          .equals(exception);
    });
  });

  group('Parse SemVer target', () {
    test('parses target', () {
      const baseTarget = 'major';

      const target = 'build';
      const indexOrPrefix = 'fake';
      const trailingModifier = 'modifier';

      check(
        parseSemVerTarget(baseTarget),
      ).equals(
        (target: baseTarget, indexOrPrefix: null, trailingModifier: null),
      );

      check(
        parseSemVerTarget('$target{$indexOrPrefix}{$trailingModifier}'),
      ).equals(
        (
          target: target,
          indexOrPrefix: indexOrPrefix,
          trailingModifier: trailingModifier
        ),
      );
    });

    test('throws exception if no target is provided', () {
      check(() => parseSemVerTarget(''))
          .throws<FormatException>()
          .has((err) => err.message, 'message')
          .equalsIgnoringWhitespace(
            'A valid target must be provided. At least one of '
            '{major, minor, patch, build, prerelease}',
          );
    });
  });

  group('Bump version', () {
    test('bumps normal semver targets', () {
      check(bumpVersion(zeroVersion, target: 'major'))
          .equals(SemVer.rawUnchecked(1, 0, 0));

      check(bumpVersion(zeroVersion, target: 'minor'))
          .equals(SemVer.rawUnchecked(0, 1, 0));

      check(bumpVersion(zeroVersion, target: 'patch'))
          .equals(SemVer.rawUnchecked(0, 0, 1));
    });
  });

  group('Bumps metadata', () {
    test('bumps first numerical semver metadata', () {
      check(bumpVersion('$zeroVersion+0', target: 'build'))
          .equals(SemVer.rawUnchecked(0, 0, 0, buildMetadata: const [1]));
    });

    test('leaves version untouched if no metadata is present', () {
      check(bumpVersion(zeroVersion, target: 'build'))
          .equals(SemVer.rawUnchecked(0, 0, 0));
    });

    test('clears metadata if no modifiers are explicitly provided', () {
      check(bumpVersion('$zeroVersion-dev', target: 'prerelease{}{}'))
          .equals(SemVer.rawUnchecked(0, 0, 0));
    });

    test(
        'appends metadata if no trailing modifier is provided '
        'and metadata is not present', () {
      const accessor = 'dev';

      check(
        bumpVersion(zeroVersion, target: 'prerelease{$accessor}{}'),
      ).equals(
        SemVer.rawUnchecked(0, 0, 0, prerelease: const [accessor]),
      );
    });

    test(
        'updates metadata in place if no trailing modifier is '
        'provided and metadata is present. Ignores any trailing metadata', () {
      const accessor = 'dev';
      const version = '$zeroVersion-$accessor.extra';

      check(
        bumpVersion(version, target: 'prerelease{$accessor}{}'),
      ).equals(
        SemVer.rawUnchecked(0, 0, 0, prerelease: const ['$accessor-1']),
      );
    });

    group('using period trailing modifier', () {
      test('when accessing modifier is present, updates in place', () {
        const accessor = 'dev';
        const version = '$zeroVersion-$accessor.extra';

        check(
          bumpVersion(version, target: 'prerelease{$accessor}{.}'),
        ).equals(
          SemVer.rawUnchecked(0, 0, 0, prerelease: const ['$accessor-1']),
        );
      });

      test(
          'when accessing modifier is present but not in metadata range '
          ', appends 1 at the end', () {
        // Access via an index in prerelease info
        check(
          bumpVersion(zeroVersion, target: 'prerelease{0}{.}'),
        ).equals(
          SemVer.rawUnchecked(0, 0, 0, prerelease: const [1]),
        );
      });

      test('appends after accessing modifier, when present', () {
        const accessor = 'alpha';
        const version = '$zeroVersion-$accessor.extra';

        const prerelease = [accessor, 'dev'];

        // When called directly
        check(
          bumpVersion(version, target: 'prerelease{$accessor}{.dev}'),
        ).equals(
          SemVer.rawUnchecked(0, 0, 0, prerelease: prerelease),
        );

        // When index is used
        check(
          bumpVersion(version, target: 'prerelease{0}{.dev}'),
        ).equals(
          SemVer.rawUnchecked(0, 0, 0, prerelease: prerelease),
        );
      });

      test(
        'appends to existing metadata, when accessing modifier is absent',
        () {
          const pre = 'dev';
          const preInfo = [pre];

          // Directly via non-existent index
          check(
            bumpVersion(zeroVersion, target: 'prerelease{0}{.$pre}'),
          ).equals(
            SemVer.rawUnchecked(0, 0, 0, prerelease: preInfo),
          );
        },
      );
    });

    group('using leading trailing modifier', () {
      test('updates existing accessor in place', () {
        const accessor = 'dev';
        const extraMeta = 'release-candidate';

        const replacement = '$accessor.$extraMeta';

        const version = '$zeroVersion-$accessor';

        check(
          bumpVersion(version, target: 'prerelease{$accessor}{$replacement}'),
        ).equals(
          SemVer.rawUnchecked(
            0,
            0,
            0,
            prerelease: const ['$accessor-1', extraMeta],
          ),
        );
      });

      test('replaces existing metadata', () {
        const accessor = 'dev';
        const replacement = 'release-candidate';

        const version = '$zeroVersion-$accessor';

        check(
          bumpVersion(version, target: 'prerelease{$accessor}{$replacement}'),
        ).equals(
          SemVer.rawUnchecked(
            0,
            0,
            0,
            prerelease: const [replacement],
          ),
        );
      });
    });

    test('appends trailing "1" if trailing modifier ends with "."', () {
      // With index
      check(
        bumpVersion(zeroVersion, target: 'prerelease{0}{.}'),
      ).equals(
        SemVer.rawUnchecked(0, 0, 0, prerelease: const [1]),
      );

      // With accessor
      check(
        bumpVersion(zeroVersion, target: 'prerelease{}{dev.}'),
      ).equals(
        SemVer.rawUnchecked(0, 0, 0, prerelease: const ['dev', 1]),
      );
    });
  });
}
