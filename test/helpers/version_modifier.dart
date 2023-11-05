part of 'helpers.dart';

class TestVersionModifier implements VersionModifiers {
  TestVersionModifier({
    required this.presetType,
    required this.version,
    required this.prerelease,
    required this.build,
    required this.keepPre,
    required this.keepBuild,
    required this.strategy,
  });

  // Default
  factory TestVersionModifier.forTest() {
    return TestVersionModifier(
      presetType: PresetType.none,
      version: null,
      prerelease: null,
      build: null,
      keepPre: false,
      keepBuild: false,
      strategy: ModifyStrategy.relative,
    );
  }

  TestVersionModifier copyWith({
    PresetType? presetType,
    String? version,
    String? prerelease,
    String? build,
    bool? keepPre,
    bool? keepBuild,
  }) {
    return TestVersionModifier(
      presetType: presetType ?? this.presetType,
      version: version ?? this.version,
      prerelease: prerelease ?? this.prerelease,
      build: build ?? this.build,
      keepPre: keepPre ?? this.keepPre,
      keepBuild: keepBuild ?? this.keepBuild,
      strategy: strategy,
    );
  }

  @override
  String? build;

  @override
  bool keepBuild;

  @override
  bool keepPre;

  @override
  String? prerelease;

  @override
  PresetType presetType;

  @override
  ModifyStrategy strategy;

  @override
  String? version;
}
