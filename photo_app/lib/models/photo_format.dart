import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'photo_format.freezed.dart';
part 'photo_format.g.dart';

@freezed
class PhotoFormat with _$PhotoFormat {
  const factory PhotoFormat({
    required String dimension,
    required double price,
    required List<String> images,
    required String title,
    required String description,
    @Default(false) bool isPopular,
    double? framePrice,
  }) = _PhotoFormat;

  factory PhotoFormat.fromJson(Map<String, Object?> json) => _$PhotoFormatFromJson(json);
}
