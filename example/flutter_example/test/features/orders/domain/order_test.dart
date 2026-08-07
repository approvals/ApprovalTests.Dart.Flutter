import 'package:flutter_example/features/orders/domain/order.dart';
import 'package:flutter_test/flutter_test.dart';

Order _order({
  required String id,
  required String productName,
  required OrderStatus status,
}) =>
    Order(
      id: id,
      productName: productName,
      status: status,
    );

void main() {
  test('uses value equality for orders with the same data', () {
    final first = _order(
      id: '1042',
      productName: 'Mechanical keyboard',
      status: OrderStatus.ready,
    );
    final same = _order(
      id: '1042',
      productName: 'Mechanical keyboard',
      status: OrderStatus.ready,
    );
    final different = _order(
      id: '1043',
      productName: 'USB-C dock',
      status: OrderStatus.processing,
    );

    expect(first, same);
    expect(first.hashCode, same.hashCode);
    expect(first, isNot(different));
  });
}
