part of 'transform_tracker.dart';

enum Origin { key, value, pair, custom }

@immutable
class TrackerKey extends Equatable{
  const TrackerKey({required this.key, required this.origin});

  final String key;

  final Origin origin;

  @override
  List<Object> get props => [key, origin];

  @override
  String toString() => key;
}

@immutable
class DualTrackerKey extends TrackerKey {
  const DualTrackerKey._({
    required super.key,
    required this.value,
    Origin? origin,
  }) : super(origin: origin ?? Origin.pair);

  factory DualTrackerKey.fromMapEntry(MapEntry<String, String> entry) {
    return DualTrackerKey._(key: entry.key, value: entry.value);
  }

  final String value;

  @override
  List<Object> get props => [...super.props, value];

  @override
  String toString() => '${super.toString()}:$value';
}
