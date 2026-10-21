class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final int? relatedOrderId;
  final int? relatedBookingId;
  final bool read;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.relatedOrderId,
    this.relatedBookingId,
    required this.read,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num).toInt(),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      relatedOrderId: json['relatedOrderId'] != null
          ? (json['relatedOrderId'] as num).toInt()
          : null,
      relatedBookingId: json['relatedBookingId'] != null
          ? (json['relatedBookingId'] as num).toInt()
          : null,
      read: json['read'] == true,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  AppNotification copyWith({bool? read, DateTime? readAt}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      relatedOrderId: relatedOrderId,
      relatedBookingId: relatedBookingId,
      read: read ?? this.read,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}
