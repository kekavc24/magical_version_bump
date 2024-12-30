import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

/// Abstraction of a input queue for a command
abstract interface class _CommandInputQueue<T> {
  /// Checks whether there is another inpur
  bool get hasNext;

  /// Obtains the next input
  FutureOr<T> get next;
}

/// A simple string queue abstraction
final class BasicInputQueue implements _CommandInputQueue<String> {
  BasicInputQueue({required List<String> inputs}) : _queue = Queue.from(inputs);

  final Queue<String> _queue;

  @override
  bool get hasNext => _queue.isNotEmpty;

  @override
  String get next => _queue.removeFirst();
}

typedef TransformedFile<T> = ({String path, T transformed});

/// A queue that reads and transforms an input from a file.
final class FileQueue<T> implements _CommandInputQueue<TransformedFile<T>> {
  FileQueue({
    required List<String> files,
    required this.transform,
  }) : _queue = BasicInputQueue(inputs: files);

  /// Holds the paths
  final BasicInputQueue _queue;

  /// Transforms data read from a file
  final Future<T> Function(File file) transform;

  @override
  bool get hasNext => _queue.hasNext;

  @override
  Future<TransformedFile<T>> get next async {
    final fileName = _queue.next;
    return (path: fileName, transformed: await transform(File(fileName)));
  }

  /// Checks if the path points to a json file
  bool _isJson(String path) {
    final split = path.split('.');

    if (split.isEmpty) return false;
    return split.last.toLowerCase() == 'json';
  }

  /// Saves [object] back to a previously read file by calling its
  /// [object.toString()] method.
  Future<void> saveFile<F>(
    String path,
    F object, {
    required bool prettifyJson,
  }) async {
    String file;

    if (_isJson(path) && prettifyJson) {
      final encoder = JsonEncoder.withIndent(' ' * 4);
      file = encoder.convert(object);
    } else {
      file = object.toString();
    }

    await File(path).writeAsString(file);
  }
}
