import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
part 'contact_info.freezed.dart';
part 'contact_info.g.dart';

@freezed
class ContactInfo with _$ContactInfo {
  const factory ContactInfo({
    required String address,
    required String phoneNumber,
    String? whatsappNumber,
    required String email,
    required String openingHours,
    String? facebookUrl,
    String? twitterUrl,
    String? instagramUrl,
    String? linkedinUrl,
  }) = _ContactInfo;

  factory ContactInfo.fromJson(Map<String, Object?> json) => _$ContactInfoFromJson(json);
}
