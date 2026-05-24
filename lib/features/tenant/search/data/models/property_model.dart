import '../../domain/entities/property_entity.dart';

class PropertyModel extends PropertyEntity {
  const PropertyModel({
    required super.title,
    required super.location,
    required super.price,
    required super.rating,
    required super.isAllInclusive,
    required super.imageUrl,
    required super.latitude,
    required super.longitude,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      title: json['title'] as String,
      location: json['location'] as String,
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      isAllInclusive: json['isAllInclusive'] as bool,
      imageUrl: json['imageUrl'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'location': location,
      'price': price,
      'rating': rating,
      'isAllInclusive': isAllInclusive,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
