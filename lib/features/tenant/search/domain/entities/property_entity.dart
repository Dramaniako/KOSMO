class PropertyEntity {
  final int id;
  final int ownerId;
  final String title;
  final String location;
  final String address;
  final double price;
  final double rating;
  final bool isAllInclusive;
  final String? allInclusiveBills;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String description;

  const PropertyEntity({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.location,
    required this.address,
    required this.price,
    required this.rating,
    required this.isAllInclusive,
    this.allInclusiveBills,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.description,
  });
}
