class PropertyEntity {
  final String title;
  final String location;
  final double price;
  final double rating;
  final bool isAllInclusive;
  final String imageUrl;
  final double latitude;
  final double longitude;

  const PropertyEntity({
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.isAllInclusive,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
  });
}
