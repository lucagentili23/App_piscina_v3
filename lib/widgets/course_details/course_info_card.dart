import 'package:app_piscina_v3/models/course.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:app_piscina_v3/utils/general_utils.dart';
import 'package:app_piscina_v3/widgets/course_details/info_row.dart';
import 'package:flutter/material.dart';

class CourseInfoCard extends StatelessWidget {
  final Course course;

  const CourseInfoCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            InfoRow(
              icon: Icons.calendar_month,
              label: "Data e Ora",
              value: dateAndTimeToString(course.date),
            ),
            const Divider(height: 30),
            InfoRow(
              icon: Icons.people,
              label: "Disponibilità",
              value: course.type == CourseType.nuoto
                  ? 'Posti Illimitati'
                  : '${24 - course.bookedSpots} posti rimanenti',
            ),
            const Divider(height: 30),
            InfoRow(
              icon: Icons.event_available,
              label: "Apertura Prenotazioni",
              value: dateToString(course.bookingOpenDate),
            ),
          ],
        ),
      ),
    );
  }
}
