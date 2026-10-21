// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeaturedContentImpl _$$FeaturedContentImplFromJson(
        Map<String, dynamic> json) =>
    _$FeaturedContentImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String,
      buttonText: json['buttonText'] as String?,
      buttonAction: json['buttonAction'] as String?,
      active: json['active'] as bool,
      priority: (json['priority'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$FeaturedContentImplToJson(
        _$FeaturedContentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'imageUrl': instance.imageUrl,
      'buttonText': instance.buttonText,
      'buttonAction': instance.buttonAction,
      'active': instance.active,
      'priority': instance.priority,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
