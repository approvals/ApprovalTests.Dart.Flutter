import 'package:flutter_example/features/orders/domain/order.dart';

abstract interface class OrdersRepository {
  Future<List<Order>> fetchOrders();
}
