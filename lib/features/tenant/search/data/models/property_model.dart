import '../../domain/entities/property_entity.dart';

class PropertyModel extends PropertyEntity {
  const PropertyModel({
    required super.id,
    required super.ownerId,
    required super.title,
    required super.location,
    required super.address,
    required super.price,
    required super.rating,
    required super.isAllInclusive,
    super.allInclusiveBills,
    required super.imageUrl,
    required super.latitude,
    required super.longitude,
    required super.description,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as int? ?? 0,
      ownerId: json['ownerId'] as int? ?? 2,
      title: json['title'] as String,
      location: json['location'] as String,
      address: json['address'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      isAllInclusive: json['isAllInclusive'] as bool,
      allInclusiveBills: json['allInclusiveBills'] as String?,
      imageUrl: json['imageUrl'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'location': location,
      'address': address,
      'price': price,
      'rating': rating,
      'isAllInclusive': isAllInclusive,
      'allInclusiveBills': allInclusiveBills,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
    };
  }
}
