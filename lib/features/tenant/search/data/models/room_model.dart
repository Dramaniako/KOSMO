class RoomModel {
  final int id;
  final int propertyId;
  final String roomNumber;
  final int? tenantId;
  final String description;
  final String imageUrl;
  final String? tenantName; // optional field populated via JOIN

  RoomModel({
    required this.id,
    required this.propertyId,
    required this.roomNumber,
    this.tenantId,
    required this.description,
    required this.imageUrl,
    this.tenantName,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as int,
      propertyId: json['property_id'] as int,
      roomNumber: json['room_number'] as String,
      tenantId: json['tenant_id'] as int?,
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      tenantName: json['tenant_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'room_number': roomNumber,
      'tenant_id': tenantId,
      'description': description,
      'image_url': imageUrl,
      'tenant_name': tenantName,
    };
  }
}
