part of 'tracker.dart';

/// Represents a custom key to use as a tracker. It holds a single value.
@immutable
base class TrackerKey<KeyT> extends Equatable {
  const TrackerKey({required this.key, required this.origin});

  const TrackerKey.fromValue(
    dynamic value,
    Origin origin,
  ) : this(key: value as KeyT, origin: origin);

  final KeyT key;

  final Origin origin;

  @override
  List<Object> get props => [key as Object, origin];

  @override
  String toString() => key.toString();
}

/// Represents a customs key. Hold 2 values. Mostly used for pairs
@immutable
final class DualTrackerKey<KeyT, OtherKeyT> extends TrackerKey<KeyT> {
  const DualTrackerKey({
    required super.key,
    required this.otherKey,
    Origin? origin,
  }) : super(origin: origin ?? Origin.pair);

  const DualTrackerKey.fromValue({
    required dynamic key,
    required dynamic otherKey,
    Origin? origin,
  }) : this(key: key as KeyT, otherKey: otherKey as OtherKeyT, origin: origin);

  DualTrackerKey.fromEntry({
    required MapEntry<dynamic, dynamic> entry,
    Origin? origin,
  }) : this(
          key: entry.key as KeyT,
          otherKey: entry.value as OtherKeyT,
          origin: origin,
        );

  final OtherKeyT otherKey;

  @override
  List<Object> get props => [...super.props, otherKey as Object];

  @override
  String toString() => '${super.toString()}:$otherKey';
}
