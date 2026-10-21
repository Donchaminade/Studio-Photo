// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PhotoFormatImpl _$$PhotoFormatImplFromJson(Map<String, dynamic> json) =>
    _$PhotoFormatImpl(
      dimension: json['dimension'] as String,
      price: (json['price'] as num).toDouble(),
      images:
          (json['images'] as List<dynamic>).map((e) => e as String).toList(),
      title: json['title'] as String,
      description: json['description'] as String,
      isPopular: json['isPopular'] as bool? ?? false,
      framePrice: (json['framePrice'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$PhotoFormatImplToJson(_$PhotoFormatImpl instance) =>
    <String, dynamic>{
      'dimension': instance.dimension,
      'price': instance.price,
      'images': instance.images,
      'title': instance.title,
      'description': instance.description,
      'isPopular': instance.isPopular,
      'framePrice': instance.framePrice,
    };
