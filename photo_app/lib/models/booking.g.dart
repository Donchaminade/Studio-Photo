// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BookingImpl _$$BookingImplFromJson(Map<String, dynamic> json) =>
    _$BookingImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      userId: (json['userId'] as num).toInt(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: $enumDecode(_$BookingStatusEnumMap, json['status']),
      type: $enumDecode(_$BookingTypeEnumMap, json['type']),
      amount: (json['amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$BookingImplToJson(_$BookingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'userId': instance.userId,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'status': _$BookingStatusEnumMap[instance.status]!,
      'type': _$BookingTypeEnumMap[instance.type]!,
      'amount': instance.amount,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$BookingStatusEnumMap = {
  BookingStatus.pending: 'PENDING',
  BookingStatus.confirmed: 'CONFIRMED',
  BookingStatus.cancelled: 'CANCELLED',
  BookingStatus.completed: 'COMPLETED',
};

const _$BookingTypeEnumMap = {
  BookingType.photoSession: 'PHOTO_SESSION',
  BookingType.event: 'EVENT',
  BookingType.portrait: 'PORTRAIT',
  BookingType.product: 'PRODUCT',
  BookingType.other: 'OTHER',
};
