part of 'transform_counter.dart';

/// Represents a custom key to use as a tracker. It holds a single value.
@immutable
base class TrackerKey<T> extends Equatable {
  const TrackerKey({required this.key, required this.origin});

  const TrackerKey.fromValue(
    dynamic value,
    Origin origin,
  ) : this(key: value as T, origin: origin);

  final T key;

  final Origin origin;

  @override
  List<Object> get props => [key as Object, origin];

  @override
  String toString() => key.toString();
}

/// Represents a customs key. Hold 2 values. Mostly used for pairs
@immutable
final class DualTrackerKey<T, U> extends TrackerKey<T> {
  const DualTrackerKey({
    required super.key,
    required this.otherKey,
    Origin? origin,
  }) : super(origin: origin ?? Origin.pair);

  const DualTrackerKey.fromValue({
    required dynamic key,
    required dynamic otherKey,
    Origin? origin,
  }) : this(key: key as T, otherKey: otherKey as U, origin: origin);

  DualTrackerKey.fromEntry({
    required MapEntry<dynamic, dynamic> entry,
    Origin? origin,
  }) : this(key: entry.key as T, otherKey: entry.value as U, origin: origin);

  final U otherKey;

  @override
  List<Object> get props => [...super.props, otherKey as Object];

  @override
  String toString() => '${super.toString()}:$otherKey';
}
