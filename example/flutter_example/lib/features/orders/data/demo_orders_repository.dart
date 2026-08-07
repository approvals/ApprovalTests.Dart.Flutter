import 'package:flutter_example/features/orders/domain/order.dart';
import 'package:flutter_example/features/orders/domain/orders_repository.dart';

final class DemoOrdersRepository implements OrdersRepository {
  @override
  Future<List<Order>> fetchOrders() => Future.value(
        const [
          Order(
            id: '1042',
            productName: 'Mechanical keyboard',
            status: OrderStatus.ready,
          ),
          Order(
            id: '1043',
            productName: 'USB-C dock',
            status: OrderStatus.processing,
          ),
        ],
      );
}
