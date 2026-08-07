enum OrderStatus {
  processing,
  ready,
}

final class Order {
  const Order({
    required this.id,
    required this.productName,
    required this.status,
  });

  final String id;
  final String productName;
  final OrderStatus status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order &&
          id == other.id &&
          productName == other.productName &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, productName, status);
}
