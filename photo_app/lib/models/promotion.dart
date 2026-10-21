import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'promotion.freezed.dart';
part 'promotion.g.dart';

@freezed
class Promotion with _$Promotion {
  const factory Promotion({
    required int id,
    required String title,
    required String imageUrl,
    String? targetUrl,
    required bool active,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Promotion;

  factory Promotion.fromJson(Map<String, Object?> json) => _$PromotionFromJson(json);
}
