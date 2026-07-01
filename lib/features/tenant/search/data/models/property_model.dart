import '../../domain/entities/property_entity.dart';

class PropertyModel extends PropertyEntity {
  const PropertyModel({
    required super.id,
    required super.ownerId,
    required super.title,
    required super.location,
    required super.address,
    required super.minPrice,
    required super.maxPrice,
    required super.rating,
    required super.imageUrl,
    required super.latitude,
    required super.longitude,
    required super.description,
    super.hasAllInclusive = false,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as int? ?? 0,
      ownerId: json['owner_id'] as int? ?? json['ownerId'] as int? ?? 2,
      title: json['title'] as String,
      location: json['location'] as String,
      address: json['address'] as String? ?? '',
      minPrice: (json['min_price'] as num?)?.toDouble() ?? (json['minPrice'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (json['max_price'] as num?)?.toDouble() ?? (json['maxPrice'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      hasAllInclusive: json['has_all_inclusive'] == true || json['has_all_inclusive'] == 1 || (json['hasAllInclusive'] as bool? ?? false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'location': location,
      'address': address,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'rating': rating,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'hasAllInclusive': hasAllInclusive,
    };
  }
}
