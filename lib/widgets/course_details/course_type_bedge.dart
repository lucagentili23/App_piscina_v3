import 'package:app_piscina_v3/theme.dart';
import 'package:flutter/material.dart';

class CourseTypeBadge extends StatelessWidget {
  final String text;

  const CourseTypeBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppTheme.lightSecondaryColor,
        ),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
