part of 'extensions.dart';

/// Extension group with general info
extension SharedArgResults on ArgResults {
  /// Get nullable value
  String? getNullableValue(String argument) => this[argument] as String?;

  /// Get a non-nullable value
  String getValue(String argument) => getNullableValue(argument)!;

  /// Get a boolean value
  bool getBooleanValue(String argument) => this[argument] as bool;

  /// Get a list of values in multi-option
  ParsedValues parsedValues(String argument) => this[argument] as List<String>;

  /// Get list of list of values in order from multioption
  ListOfParsedValues parsedValueList(String argument) => parsedValues(argument)
      .map((e) => e.splitAndTrim(',').retainNonEmpty())
      .toList();

  PathInfo get pathInfo {
    // Read paths before hand
    final paths = this['directory'];

    return (
      requestPath: this['request-path'] as bool,
      paths: paths is List<String> ? paths : [paths as String],
    );
  }
}

/// Extension group with version modifier results
extension VersionModifierResults on ArgResults {
  /// Check set version
  String? get setVersion => getNullableValue('set-version');

  /// Check set prerelease
  String? get setPrerelease => getNullableValue('set-prerelease');

  /// Check set build
  String? get setBuild => getNullableValue('set-build');

  /// Check whether to retain prerelease
  bool get keepPre => getBooleanValue('keep-pre');

  /// Check whether to retain build
  bool get keepBuild => getBooleanValue('keep-build');

  /// Check targets
  List<String> get targets => parsedValues('targets');

  /// Check strategy
  ModifyStrategy strategy() =>
      ModifyStrategy.values.byName(getValue('strategy'));

  /// Check preset
  PresetType checkPreset({required bool ignoreFlag}) {
    // Check preset flag. Set to false if we want to ignore
    final presetAll = ignoreFlag ? !ignoreFlag : getBooleanValue('preset');

    // Preset only version if preset is false & version is not null
    final presetVersion = !presetAll && getNullableValue('set-version') != null;

    if (presetVersion) return PresetType.version;

    if (presetAll) return PresetType.all;

    return PresetType.none;
  }
}

/// Extension for obtaining walker results
extension WalkerResults on ArgResults {
  /// Get the format to use while printing to console
  ConsoleViewFormat get viewFormat =>
      ConsoleViewFormat.values.byName(getValue('view-format'));

  /// Get aggregator type
  AggregateType get _aggregatorType =>
      AggregateType.values.byName(getValue('aggregate'));

  /// Get limit of aggregation
  int? get _limit => int.tryParse(getValue('limit-to'));

  /// Get keys to find
  ParsedValues get mapKeys => parsedValues('keys');

  /// Get keys to be renamed
  ListOfParsedValues get targetKeys => parsedValueList('keys');

  /// Get values to find
  ParsedValues get mapValues => parsedValues('values');

  /// Get values to be replaced
  ListOfParsedValues get targetValues => parsedValueList('values');

  /// Get pairs
  ListOfParsedValues get mapPairs => parsedValueList('pairs');

  /// Get key order
  OrderType get keyOrder => OrderType.values.byName(getValue('key-order'));

  /// Get replacements for key/values
  ParsedValues get replacementCandidates => parsedValues('subtitute');

  /// Get the aggregator to use to "walk"
  Aggregator getAggregator() {
    // If Aggregator is count and limit is null, throw
    if (_aggregatorType == AggregateType.count && _limit == null) {
      throw MagicalException(
        violation: 'A valid count is required for "limit-to"',
      );
    }

    return (
      type: _aggregatorType,
      applyToEach: true,
      count: _limit,
      viewFormat: viewFormat,
    );
  }
}
