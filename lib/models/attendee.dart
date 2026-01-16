class Attendee {
  final String id;
  final String userId;
  final String? childId;
  final String displayedName;
  final String displayedPhotoUrl;

  Attendee({
    required this.id,
    required this.userId,
    this.childId,
    required this.displayedName,
    required this.displayedPhotoUrl,
  });

  factory Attendee.fromMap(Map<String, dynamic> data, String documentId) {
    return Attendee(
      id: documentId,
      userId: data['userId'] ?? '',
      childId: data['childId'],
      displayedName: data['displayedName'] ?? '',
      displayedPhotoUrl: data['displayedPhotoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'childId': childId,
      'displayedName': displayedName,
      'displayedPhotoUrl': displayedPhotoUrl,
    };
  }
}
