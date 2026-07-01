class PropertyEntity {
  final int id;
  final int ownerId;
  final String title;
  final String location;
  final String address;
  final double minPrice;
  final double maxPrice;
  final double rating;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String description;
  final bool hasAllInclusive;

  const PropertyEntity({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.location,
    required this.address,
    required this.minPrice,
    required this.maxPrice,
    required this.rating,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.description,
    this.hasAllInclusive = false,
  });
}
