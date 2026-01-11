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

  Future<String?> unbookUserWithoutChildrenFromCourse(
    String courseId,
    String userId,
  ) async {
    try {
      final courseRef = _db.collection('courses').doc(courseId);

      final courseSnapshot = await courseRef.get();

      if (!courseSnapshot.exists) {
        throw 'Il corso non esiste più.';
      }
      final currentBooked = courseSnapshot.get('bookedSpots');

      final querySnapshot = await courseRef
          .collection('attendees')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      await courseRef.update({'bookedSpots': currentBooked - 1});

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> unbookFromCourse(
    String courseId,
    String id,
    bool? isUser,
  ) async {
    try {
      final courseRef = _db.collection('courses').doc(courseId);

      Query query = courseRef.collection('attendees');

      if (isUser == true) {
        query = query
            .where('userId', isEqualTo: id)
            .where('childId', isEqualTo: null);
      } else {
        query = query.where('childId', isEqualTo: id);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        return "Nessuna prenotazione trovata.";
      }

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      courseRef.update({'bookedSpots': FieldValue.increment(-1)});

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> isBooked(String userId, String courseId) async {
    try {
      final courseRef = await _db
          .collection('courses')
          .doc(courseId)
          .collection('attendees')
          .where('userId', isEqualTo: userId)
          .get();

      if (courseRef.docs.isNotEmpty) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
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

  // In course_service.dart

  // 1. Modifica getCourseAttendeesForUser per includere l'ID del documento (docId)
  Future<List<Map<String, dynamic>>> getCourseAttendeesForUser(
    String courseId,
    String userId,
  ) async {
    try {
      List<Map<String, dynamic>> attendees = [];

      final querySnapshot = await _db
          .collection('courses')
          .doc(courseId)
          .collection('attendees')
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          final Map<String, dynamic> attendee = {};
          final childId = doc.get('childId');

          // Salviamo l'ID del documento Firestore, che è univoco per ogni prenotazione
          attendee['docId'] = doc.id;

          if (childId != null) {
            attendee['id'] = childId;
            attendee['isChild'] = true;
            attendee['displayName'] = doc.get('displayName');
          } else {
            attendee['id'] = doc.get('userId');
            attendee['isChild'] = false;
            attendee['displayName'] = doc.get('displayName');
          }
          attendees.add(attendee);
        }

        return attendees;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<String?> removeAttendee(String courseId, String attendeeDocId) async {
    try {
      final courseRef = _db.collection('courses').doc(courseId);
      final attendeeRef = courseRef.collection('attendees').doc(attendeeDocId);

      // Verifichiamo che il documento esista prima di procedere
      final docSnapshot = await attendeeRef.get();
      if (!docSnapshot.exists) {
        return "Prenotazione non trovata.";
      }

      // Eliminiamo il documento specifico
      await attendeeRef.delete();

      // Aggiorniamo il contatore dei posti
      await courseRef.update({'bookedSpots': FieldValue.increment(-1)});

      return null;
    } catch (e) {
      return e.toString();
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
      return [];
    }
  }
}
