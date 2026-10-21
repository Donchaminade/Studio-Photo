class PhotoFrame {
  final int id;
  final String name;
  final List<String> images;
  final String description;
  final int sortOrder;

  const PhotoFrame({
    required this.id,
    required this.name,
    required this.images,
    required this.description,
    required this.sortOrder,
  });

  factory PhotoFrame.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    return PhotoFrame(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      images: rawImages is List
          ? rawImages.map((e) => e.toString()).toList()
          : const [],
      description: json['description'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  String? get primaryImage => images.isNotEmpty ? images.first : null;
}
