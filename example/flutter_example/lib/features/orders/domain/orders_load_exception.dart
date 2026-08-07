final class OrdersLoadException implements Exception {
  const OrdersLoadException(this.message);

  final String message;

  @override
  String toString() => 'OrdersLoadException: $message';
}
