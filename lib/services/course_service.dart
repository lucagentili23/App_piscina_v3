import 'package:app_piscina_v3/models/attendee.dart';
import 'package:app_piscina_v3/models/course.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> createEvent({
    required CourseType courseType,
    required DateTime date,
  }) async {
    try {
      final docRef = _db.collection('courses').doc();

      final bookingOpenDate = date.subtract(Duration(days: 14));

      final newEvent = Course(
        id: docRef.id,
        type: courseType,
        date: date,
        bookingOpenDate: bookingOpenDate,
        maxSpots: courseType == CourseType.idrobike ? 24 : null,
      );

      await docRef.set(newEvent.toMap());

      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<List<Course>> getCoursesStream() {
    return _db
        .collection('courses')
        .where('date', isGreaterThan: Timestamp.now())
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Course.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Future<Course?> getCourseById(String id) async {
    try {
      final doc = await _db.collection('courses').doc(id).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        return Course.fromMap(data, id);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<String?> bookCourse(String courseId, List<Attendee> attendees) async {
    try {
      final courseRef = _db.collection('courses').doc(courseId);

      final courseSnapshot = await courseRef.get();

      if (!courseSnapshot.exists) {
        throw 'Il corso non esiste più.';
      }
      final currentBooked = courseSnapshot.get('bookedSpots');
      final maxSpots = courseSnapshot.get('maxSpots');

      if (maxSpots != null && (currentBooked + attendees.length) > maxSpots) {
        throw 'Posti insufficienti. Rimangono ${maxSpots - currentBooked} posti.';
      }

      for (var attendee in attendees) {
        final attendeeRef = courseRef.collection('attendees').doc();

        await attendeeRef.set({
          'userId': attendee.userId,
          'childId': attendee.childId,
          'displayName': attendee.displayedName,
          'photoUrl': attendee.displayedPhotoUrl,
          'bookedAt': FieldValue.serverTimestamp(),
        });
      }

      await courseRef.update({'bookedSpots': currentBooked + attendees.length});

      return null;
    } catch (e) {}
    return null;
  }
}
