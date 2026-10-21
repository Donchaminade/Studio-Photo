import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'featured_content.freezed.dart';
part 'featured_content.g.dart';

@freezed
class FeaturedContent with _$FeaturedContent {
  const factory FeaturedContent({
    required int id,
    required String title,
    required String imageUrl,
    String? buttonText,
    String? buttonAction,
    required bool active,
    required int priority,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _FeaturedContent;

  factory FeaturedContent.fromJson(Map<String, Object?> json) => _$FeaturedContentFromJson(json);
}
