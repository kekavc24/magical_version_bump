part of 'transform_tracker.dart';

enum Origin { key, value, pair }

@immutable
class TrackerKey {
  const TrackerKey({required this.key, required this.origin});

  final String key;

  final Origin origin;

  @override
  bool operator ==(Object other) {
    return other is TrackerKey && other.key == key && other.origin == origin;
  }

  @override
  int get hashCode => Object.hashAll([key, origin]);

  @override
  String toString() => key;
}

@immutable
class DualTrackerKey extends TrackerKey {
  const DualTrackerKey._({
    required super.key,
    required this.value,
  }) : super(origin: Origin.pair);

  factory DualTrackerKey.fromMapEntry(MapEntry<String, String> entry) {
    return DualTrackerKey._(key: entry.key, value: entry.value);
  }

  final String value;

  @override
  bool operator ==(Object other) {
    return other is DualTrackerKey && super == other && value == other.value;
  }

  @override
  int get hashCode => Object.hashAll([super.key, value, super.origin]);

  @override
  String toString() => '${super.toString()}:$value';
}
