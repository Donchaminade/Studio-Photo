// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderImpl _$$OrderImplFromJson(Map<String, dynamic> json) => _$OrderImpl(
      id: (json['id'] as num).toInt(),
      orderItems: (json['orderItems'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      deliveryType: json['deliveryType'] as String,
      deliveryAddress: json['deliveryAddress'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$OrderImplToJson(_$OrderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderItems': instance.orderItems,
      'status': instance.status,
      'totalAmount': instance.totalAmount,
      'paymentMethod': instance.paymentMethod,
      'deliveryType': instance.deliveryType,
      'deliveryAddress': instance.deliveryAddress,
      'createdAt': instance.createdAt.toIso8601String(),
    };
