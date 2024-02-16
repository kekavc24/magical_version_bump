/// This is a custom exception class. Nothing fancy, added to catch command
/// exceptions
class MagicalException implements Exception {
  MagicalException({required this.message});

  /// Command message or error
  final String message;

  @override
  String toString() => message;
}
