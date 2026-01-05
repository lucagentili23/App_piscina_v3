class Child {
  final String id;
  final String firstName;
  final String lastName;
  final String photoUrl;
  final String gender;

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
      gender: data['gender'] ?? 'm',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'gender': gender,
    };
  }

  String get fullName => '$firstName $lastName';
}
