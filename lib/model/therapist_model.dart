// lib/models/therapist_model.dart
class TherapistModel {
  final String therapistId;
  final String name;
  final String? specialization;
  final int experience;
  final double rating;
  final String? profileImage;
  final Map<String, List<String>> availability;

  TherapistModel({
    required this.therapistId,
    required this.name,
    this.specialization,
    required this.experience,
    required this.rating,
    this.profileImage,
    required this.availability,
  });

  factory TherapistModel.fromJson(Map<String, dynamic> json) {
    return TherapistModel(
      therapistId: json['therapistId'],
      name: json['name'],
      specialization: json['specialization'],
      experience: json['experience'],
      rating: json['rating'],
      profileImage: json['profileImage'],
      availability: Map<String, List<String>>.from(
          json['availability'].map((key, value) => MapEntry(key, List<String>.from(value)))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'therapistId': therapistId,
      'name': name,
      'specialization': specialization,
      'experience': experience,
      'rating': rating,
      'profileImage': profileImage,
      'availability': availability,
    };
  }
}