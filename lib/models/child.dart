import 'package:app_piscina_v3/utils/enums.dart';

class Child {
  final String id;
  final String firstName;
  final String lastName;
  final String photoUrl;
  final Gender gender;

  Child({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.photoUrl,
    required this.gender,
  });

  factory Child.fromMap(Map<String, dynamic> data, String documentId) {
    return Child(
      id: documentId,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      gender: data['gender'] == 'm'
          ? Gender.m
          : (data['gender'] == 'f' ? Gender.f : Gender.x),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'gender': gender.name,
    };
  }

  String get fullName => '$firstName $lastName';
}
