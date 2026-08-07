import 'package:flutter_example/features/orders/domain/order.dart';
import 'package:flutter_example/features/orders/domain/orders_repository.dart';

typedef FetchOrders = Future<List<Order>> Function();

final class FakeOrdersRepository implements OrdersRepository {
  FakeOrdersRepository(this._fetchOrders);

  final FetchOrders _fetchOrders;

  @override
  Future<List<Order>> fetchOrders() => _fetchOrders();
}
