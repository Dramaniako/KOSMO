class LandlordPropertyModel {
  final int id;
  final String title;
  final String address;
  final int totalRooms;
  final int occupiedRooms;
  final String imageUrl;
  final String description;
  final String allInclusiveBills;
  final double price;

  const LandlordPropertyModel({
    required this.id,
    required this.title,
    required this.address,
    required this.totalRooms,
    required this.occupiedRooms,
    required this.imageUrl,
    required this.description,
    required this.allInclusiveBills,
    required this.price,
  });

  factory LandlordPropertyModel.fromJson(Map<String, dynamic> json) {
    return LandlordPropertyModel(
      id: json['id'] as int,
      title: json['title'] as String,
      address: json['address'] as String,
      totalRooms: json['totalRooms'] as int,
      occupiedRooms: json['occupiedRooms'] as int,
      imageUrl: json['imageUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      allInclusiveBills: json['allInclusiveBills'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
