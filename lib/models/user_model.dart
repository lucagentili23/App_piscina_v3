import 'package:app_piscina_v3/utils/enums.dart';

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final Gender gender;
  final String photoUrl;
  final UserRole role;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.photoUrl,
    this.role = UserRole.user,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      gender: data['gender'] == 'm' ? Gender.m : Gender.f,
      photoUrl: data['photoUrl'] ?? '',
      role: data['role'] == 'admin' ? UserRole.admin : UserRole.user,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'gender': gender.name,
      'photoUrl': photoUrl,
      'role': role == UserRole.admin ? 'admin' : 'user',
    };
  }

  String get fullName => '$firstName $lastName';
}
