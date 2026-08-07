import 'package:flutter_example/features/orders/domain/order.dart';

const readyOrderFixture = Order(
  id: '1042',
  productName: 'Mechanical keyboard',
  status: OrderStatus.ready,
);

const processingOrderFixture = Order(
  id: '1043',
  productName: 'USB-C dock',
  status: OrderStatus.processing,
);

const ordersFixture = [
  readyOrderFixture,
  processingOrderFixture,
];
