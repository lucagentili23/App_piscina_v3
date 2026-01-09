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
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getBookedCourses(String userId) async {
    try {
      final querySnapshot = await _db
          .collectionGroup('attendees')
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isEmpty) return [];

      final Map<String, List<String>> courseAttendeesMap = {};

      for (var doc in querySnapshot.docs) {
        final courseId = doc.reference.parent.parent!.id;
        final data = doc.data();
        final name = data['displayName'];

        if (!courseAttendeesMap.containsKey(courseId)) {
          courseAttendeesMap[courseId] = [];
        }
        courseAttendeesMap[courseId]!.add(name);
      }

      List<Map<String, dynamic>> results = [];

      for (String courseId in courseAttendeesMap.keys) {
        final course = await getCourseById(courseId);

        if (course != null && course.date.isAfter(DateTime.now())) {
          results.add({
            'course': course,
            'names': courseAttendeesMap[courseId]!,
          });
        }
      }

      results.sort((a, b) {
        final dateA = (a['course'] as Course).date;
        final dateB = (b['course'] as Course).date;
        return dateA.compareTo(dateB);
      });

      return results;
    } catch (e) {
      return [];
    }
  }

  Future<List<Attendee>> getCourseAttendees(String courseId) async {
    try {
      List<Attendee> attendees = [];

      final querySnapshot = await _db
          .collection('courses')
          .doc(courseId)
          .collection('attendees')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var attendee in querySnapshot.docs) {
          attendees.add(Attendee.fromMap(attendee.data(), attendee.id));
        }
        return attendees;
      } else {
        return [];
      }
    } catch (e) {
      print(e);
      return [];
    }
  }
}
