import 'package:app_piscina_v3/utils/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final CourseType type;
  final DateTime date;
  final DateTime bookingOpenDate;
  final int? maxSpots;
  final int bookedSpots;

  Course({
    required this.id,
    required this.type,
    required this.date,
    required this.bookingOpenDate,
    this.maxSpots,
    this.bookedSpots = 0,
  });

  bool get isBookingOpen {
    final now = DateTime.now();
    return now.isAfter(bookingOpenDate) && now.isBefore(date);
  }

  bool get isFull {
    if (maxSpots == null) return false;
    return bookedSpots >= maxSpots!;
  }

  factory Course.fromMap(Map<String, dynamic> data, String documentId) {
    return Course(
      id: documentId,
      type: data['type'] == 'idrobike' ? CourseType.idrobike : CourseType.nuoto,
      date: (data['date'] as Timestamp).toDate(),
      bookingOpenDate: (data['bookingOpenDate'] as Timestamp).toDate(),
      maxSpots: data['maxSpots'],
      bookedSpots: data['bookedSpots'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'bookingOpenDate': Timestamp.fromDate(bookingOpenDate),
      'maxSpots': maxSpots,
      'bookedSpots': bookedSpots,
    };
  }
}
