import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/utils/command_handler/mixins/command_mixins.dart';
import 'package:magical_version_bump/src/utils/models/magical_data_model.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../helpers/helpers.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _MockPrepper with PrepCommand {}

void main() {
  group('prep command mixin test', () {
    late Logger logger;
    late _MockPrepper prepper;

    setUp(() {
      logger = _MockLogger();
      prepper = _MockPrepper();

      when(() => logger.progress(any())).thenReturn(_MockProgress());
    });

    test('args prepped with no path', () async {
      final args = ['--bump', '--major'];

      const action = 'bump';

      final targets = ['major'];

      final preppedData = await prepper.readArgs(args: args, logger: logger);

      verify(() => logger.progress('Checking arguments')).called(1);

      final targetsMatch = const ListEquality<String>()
          .equals(targets, preppedData.versionTargets);

      expect(preppedData, isA<PrepCommandData>());
      expect(preppedData.action, action);
      expect(preppedData.requestPath, false);
      expect(targetsMatch, true);
    });

    test('args prepped with path', () async {
      final args = ['--dump', '--major', '--with-path'];

      const action = 'dump';

      final targets = ['major'];

      final preppedData = await prepper.readArgs(args: args, logger: logger);

      verify(() => logger.progress('Checking arguments')).called(1);

      final targetsMatch = const ListEquality<String>()
          .equals(targets, preppedData.versionTargets);

      expect(preppedData, isA<PrepCommandData>());
      expect(preppedData.action, action);
      expect(preppedData.requestPath, true);
      expect(targetsMatch, true);
    });

    test('throws error when missing args', () async {
      final args = <String>[];

      const errorMessage = 'No arguments found';

      final preppedData = prepper.readArgs(args: args, logger: logger);

      expect(() async => preppedData, throwsViolation(errorMessage));
    });

    test('throws error with undefined flags', () {
      // correct flag is --dump or -d , --major
      final args = ['--dumpy', '--majorly'];

      final undefinedFlags = ['dumpy', 'majorly'];

      final violation =
          """${undefinedFlags.join(', ')} are not  defined flags""";

      final preppedData = prepper.readArgs(args: args, logger: logger);

      expect(() async => preppedData, throwsViolation(violation));
    });

    test('throws error when action flag not first', () {
      // Action flags include --bump, -b, --dump, -d
      final args = ['--major', '--bump', '--with-path'];

      final violation =
          """Error! ${prepper.actions.join(', ')} flags should come first""";

      final preppedData = prepper.readArgs(args: args, logger: logger);

      expect(() async => preppedData, throwsViolation(violation));
    });

    test('throws error when no target flag provided', () {
      /// Target flags include --major --minor --patch --build-number
      /// '--with-path' is a target flag but has no functionality just nudges
      /// cli to request path.
      final args = ['--dump', '--with-path'];

      final violation =
          """Error! Command should have at least one of ${prepper.targets.take(4).join(', ')} flags""";

      final preppedData = prepper.readArgs(args: args, logger: logger);

      expect(() async => preppedData, throwsViolation(violation));
    });

    test('throws error when flags are duplicated', () {
      final args = ['--bump', '--bump', '--major'];

      const repeatedFlag = MapEntry('bump', 2);

      final violation =
          '''Error! Found repeated flags:\n${repeatedFlag.key} -> ${repeatedFlag.value}\n''';

      final preppedData = prepper.readArgs(args: args, logger: logger);

      expect(() async => preppedData, throwsViolation(violation));
    });
  });
}
