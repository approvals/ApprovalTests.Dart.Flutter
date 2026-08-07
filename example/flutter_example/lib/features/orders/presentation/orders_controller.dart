import 'package:flutter/foundation.dart';
import 'package:flutter_example/features/orders/domain/orders_load_exception.dart';
import 'package:flutter_example/features/orders/domain/orders_repository.dart';
import 'package:flutter_example/features/orders/presentation/orders_state.dart';

final class OrdersController extends ValueNotifier<OrdersState> {
  OrdersController({required OrdersRepository repository})
      : _repository = repository,
        super(const OrdersInitial());

  final OrdersRepository _repository;
  bool _isDisposed = false;

  Future<void> load() async {
    if (_isDisposed) return;
    _emit(const OrdersLoading());
    try {
      final orders = await _repository.fetchOrders();
      _emit(OrdersLoaded(orders));
    } on OrdersLoadException catch (error) {
      _emit(OrdersFailure(error.message));
    }
  }

  void _emit(OrdersState state) {
    if (!_isDisposed) value = state;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
