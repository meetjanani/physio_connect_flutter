// lib/models/session_type_model.dart
class SessionTypeModel {
  final String sessionTypeId;
  final String name;
  final String? description;
  final int durationMinutes;
  final double price;
  final String? image;

  SessionTypeModel({
    required this.sessionTypeId,
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.price,
    this.image,
  });

  factory SessionTypeModel.fromJson(Map<String, dynamic> json) {
    return SessionTypeModel(
      sessionTypeId: json['sessionTypeId'],
      name: json['name'],
      description: json['description'],
      durationMinutes: json['durationMinutes'],
      price: json['price'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionTypeId': sessionTypeId,
      'name': name,
      'description': description,
      'durationMinutes': durationMinutes,
      'price': price,
      'image': image,
    };
  }
}