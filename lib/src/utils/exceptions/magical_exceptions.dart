/// This is a custom exception class. Nothing fancy, added to catch command
/// exceptions
class MagicalException implements Exception {
  MagicalException({required this.violation});

  /// String command violation or error
  final String violation;

  @override
  String toString() => violation;
}
