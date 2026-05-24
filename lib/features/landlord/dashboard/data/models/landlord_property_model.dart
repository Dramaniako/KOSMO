class LandlordPropertyModel {
  final String title;
  final String address;
  final int totalRooms;
  final int occupiedRooms;
  final String imageUrl;

  const LandlordPropertyModel({
    required this.title,
    required this.address,
    required this.totalRooms,
    required this.occupiedRooms,
    required this.imageUrl,
  });

  factory LandlordPropertyModel.fromJson(Map<String, dynamic> json) {
    return LandlordPropertyModel(
      title: json['title'] as String,
      address: json['address'] as String,
      totalRooms: json['totalRooms'] as int,
      occupiedRooms: json['occupiedRooms'] as int,
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }
}
