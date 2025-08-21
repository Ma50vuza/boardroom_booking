class Boardroom {
  final String id;
  final String name;
  final int capacity;
  final String location;
  final List<String> amenities;
  final List<BoardroomImage> images;
  final bool isActive;
  final String? description;
  final DateTime createdAt;

  Boardroom({
    required this.id,
    required this.name,
    required this.capacity,
    required this.location,
    required this.amenities,
    required this.images,
    required this.isActive,
    this.description,
    required this.createdAt,
  });

  factory Boardroom.fromJson(Map<String, dynamic> json) {
    return Boardroom(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      capacity: json['capacity'] ?? 0,
      location: json['location'] ?? '',
      amenities: List<String>.from(json['amenities'] ?? []),
      images: (json['images'] as List<dynamic>?)
              ?.map((img) => BoardroomImage.fromJson(img))
              .toList() ??
          [],
      isActive: json['isActive'] ?? true,
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class BoardroomImage {
  final String url;
  final String alt;
  final bool isPrimary;
  final String? fileId;

  BoardroomImage({
    required this.url,
    required this.alt,
    required this.isPrimary,
    this.fileId,
  });

  factory BoardroomImage.fromJson(Map<String, dynamic> json) {
    return BoardroomImage(
      url: json['url'] ?? '',
      alt: json['alt'] ?? '',
      isPrimary: json['isPrimary'] ?? false,
      fileId: json['fileId'],
    );
  }
}
