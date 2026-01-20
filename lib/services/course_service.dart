import 'package:app_piscina_v3/models/attendee.dart';
import 'package:app_piscina_v3/models/course.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> createCourse({
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

  Future<bool> editCourse(String courseId, DateTime date) async {
    try {
      final bookingOpenDate = date.subtract(Duration(days: 14));

      await _db.collection('courses').doc(courseId).update({
        'date': Timestamp.fromDate(date),
        'bookingOpenDate': bookingOpenDate,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    try {
      await _db.collection('courses').doc(courseId).delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<List<Course>> getCoursesStream() {
    return _db
        .collection('courses')
        .where('date', isGreaterThanOrEqualTo: DateTime.now())
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Course.fromMap(doc.data(), doc.id);
          }).toList();
        })
        .handleError((error) {
          return <Course>[];
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

  Future<bool> bookCourse(String courseId, List<Attendee> attendees) async {
    try {
      final courseRef = _db.collection('courses').doc(courseId);

      final courseSnapshot = await courseRef.get();

      if (!courseSnapshot.exists) {
        return false;
      }

      final currentBooked = courseSnapshot.get('bookedSpots');
      final maxSpots = courseSnapshot.get('maxSpots');

      if (maxSpots != null && (currentBooked + attendees.length) > maxSpots) {
        return false;
      }

      for (var attendee in attendees) {
        final attendeeRef = courseRef.collection('attendees').doc();
        final data = attendee.toMap();

        await attendeeRef.set(data);
      }

      await courseRef.update({'bookedSpots': currentBooked + attendees.length});

      return true;
    } catch (e) {
      return false;
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
        final name = data['displayedName'];

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

  Future<List<Attendee>> getCourseAttendeesForUser(
    String courseId,
    String userId,
  ) async {
    try {
      List<Attendee> attendees = [];

      final querySnapshot = await _db
          .collection('courses')
          .doc(courseId)
          .collection('attendees')
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          final childId = doc.get('childId');

          if (childId != null) {
            final attendee = Attendee(
              id: doc.id,
              userId: userId,
              displayedName: doc.get('displayedName'),
              childId: childId,
              displayedPhotoUrl: doc.get('displayedPhotoUrl'),
            );
            attendees.add(attendee);
          } else {
            final attendee = Attendee(
              id: doc.id,
              userId: userId,
              displayedName: doc.get('displayedName'),
              childId: null,
              displayedPhotoUrl: doc.get('displayedPhotoUrl'),
            );
            attendees.add(attendee);
          }
        }

        return attendees;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> removeAttendee(String courseId, String attendeeDocId) async {
    try {
      final courseRef = _db.collection('courses').doc(courseId);
      final attendeeRef = courseRef.collection('attendees').doc(attendeeDocId);

      final docSnapshot = await attendeeRef.get();
      if (!docSnapshot.exists) {
        return false;
      }

      await attendeeRef.delete();

      await courseRef.update({'bookedSpots': FieldValue.increment(-1)});

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Attendee>> getCourseAttendeesForAdmin(String courseId) async {
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

  Future<List<Course>> getDailyCourses() async {
    try {
      final now = DateTime.now();

      final startOfDay = DateTime(now.year, now.month, now.day);

      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _db
          .collection('courses')
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThan: endOfDay)
          .orderBy('date')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs
            .map((doc) => Course.fromMap(doc.data(), doc.id))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
