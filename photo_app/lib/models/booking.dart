import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'booking.freezed.dart';
part 'booking.g.dart';

enum BookingStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('COMPLETED')
  completed,
}

enum BookingType {
  @JsonValue('PHOTO_SESSION')
  photoSession,
  @JsonValue('EVENT')
  event,
  @JsonValue('PORTRAIT')
  portrait,
  @JsonValue('PRODUCT')
  product,
  @JsonValue('OTHER')
  other,
}

@freezed
class Booking with _$Booking {
  const factory Booking({
    required int id,
    required String title,
    String? description,
    required int userId, // ID utilisateur lié à la réservation
    required DateTime startTime,
    required DateTime endTime,
    required BookingStatus status,
    required BookingType type, // Nouveau champ
    required double amount, // Nouveau champ (BigDecimal en Java -> double en Dart)
    String? notes,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Booking;

  factory Booking.fromJson(Map<String, Object?> json) => _$BookingFromJson(json);

  /// Utilise cette méthode quand la réponse du backend peut contenir
  /// un objet 'user' imbriqué ou un 'amount' nul.
  static Booking fromRawJson(Map<String, dynamic> json) {
    final processed = Map<String, dynamic>.from(json);
    if (processed['userId'] == null && processed['user'] != null) {
      if (processed['user'] is Map) {
        processed['userId'] = (processed['user'] as Map)['id'];
      } else if (processed['user'] is num) {
        processed['userId'] = processed['user'];
      }
    }
    processed['amount'] ??= 0.0;
    return _$BookingFromJson(processed);
  }

  factory Booking.fromId({ // Factory pour créer une réservation sans ID
    required String title,
    String? description,
    required int userId,
    required DateTime startTime,
    required DateTime endTime,
    required BookingType type,
    required double amount,
    BookingStatus? status,
    String? notes,
  }) => _Booking(
    id: 0, // Placeholder ID
    title: title,
    description: description,
    userId: userId,
    startTime: startTime,
    endTime: endTime,
    status: status ?? BookingStatus.pending,
    type: type,
    amount: amount,
    notes: notes,
    createdAt: DateTime.now(),
    updatedAt: null,
  );
}
