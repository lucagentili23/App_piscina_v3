class Attendee {
  final String id; // ID della prenotazione
  final String userId; // ID del genitore (account che ha prenotato)
  final String? childId; // Se null è il genitore stesso, altrimenti il figlio
  final String displayedName;
  final String displayedPhotoUrl;

  Attendee({
    required this.id,
    required this.userId,
    this.childId,
    required this.displayedName,
    this.displayedPhotoUrl = '',
  });

  factory Attendee.fromMap(Map<String, dynamic> data, String documentId) {
    return Attendee(
      id: documentId,
      userId: data['userId'] ?? '',
      childId: data['childId'],
      displayedName: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
          .trim(),
      displayedPhotoUrl: data['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap(String firstName, String lastName, String? photo) {
    return {
      'userId': userId,
      'childId': childId,
      'firstName': firstName, // Denormalizziamo
      'lastName': lastName, // Denormalizziamo
      'photoUrl': photo, // Denormalizziamo
    };
  }
}
