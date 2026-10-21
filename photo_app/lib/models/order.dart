import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:Picon/models/order_item.dart';

part 'order.freezed.dart';
part 'order.g.dart';

@freezed
class Order with _$Order {
  const factory Order({
    required int id,
    required List<OrderItem> orderItems,
    required String status,
    required double totalAmount,
    required String paymentMethod,
    required String deliveryType,
    String? deliveryAddress,
    required DateTime createdAt,
  }) = _Order;

  factory Order.fromJson(Map<String, Object?> json) => _$OrderFromJson(json);
}
