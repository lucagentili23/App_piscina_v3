import 'package:flutter/material.dart';

class CourseDetailsAdmin extends StatelessWidget {
  final String courseId;

  const CourseDetailsAdmin({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dettaglio corso')),
      body: Center(child: Text('CourseDetailsAdmin')),
    );
  }
}
