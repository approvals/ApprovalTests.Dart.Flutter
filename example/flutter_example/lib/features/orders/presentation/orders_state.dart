import 'package:flutter_example/features/orders/domain/order.dart';

sealed class OrdersState {
  const OrdersState();
}

final class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

final class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

final class OrdersLoaded extends OrdersState {
  OrdersLoaded(Iterable<Order> orders) : orders = List.unmodifiable(orders);

  final List<Order> orders;
}

final class OrdersFailure extends OrdersState {
  const OrdersFailure(this.message);

  final String message;
}
