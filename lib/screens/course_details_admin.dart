import 'package:app_piscina_v3/layouts/admin_layout.dart';
import 'package:app_piscina_v3/models/attendee.dart';
import 'package:app_piscina_v3/models/course.dart';
import 'package:app_piscina_v3/screens/edit_course.dart';
import 'package:app_piscina_v3/screens/view_attendees.dart';
import 'package:app_piscina_v3/services/course_service.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:app_piscina_v3/widgets/course_details/course_info_card.dart';
import 'package:app_piscina_v3/widgets/course_details/course_type_bedge.dart';
import 'package:flutter/material.dart';

class CourseDetailsAdmin extends StatefulWidget {
  final String courseId;

  const CourseDetailsAdmin({super.key, required this.courseId});

  @override
  State<CourseDetailsAdmin> createState() => _CourseDetailsAdminState();
}

class _CourseDetailsAdminState extends State<CourseDetailsAdmin> {
  final _courseService = CourseService();
  Course? _course;
  bool _isLoading = true;
  List<Attendee> _attendees = [];

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  Future<void> _loadData() async {
    try {
      final courseData = await _courseService.getCourseById(widget.courseId);
      final attendees = await _courseService.getCourseAttendeesForAdmin(
        widget.courseId,
      );

      if (mounted) {
        setState(() {
          _course = courseData;
          _attendees = attendees;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _deleteCourse() async {
    try {
      final confirm = await showConfirmDialog(
        context,
        'Sei sicuro di voler eliminare definitivamente il corso?',
      );

      if (!confirm) return;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final outcome = await _courseService.deleteCourse(widget.courseId);

      if (outcome && mounted) {
        Navigator.pop(context);
        showSuccessDialog(
          context,
          'Corso eliminato con successo',
          onContinue: () => Nav.replace(context, const AdminLayout()),
        );
      }

      if (!outcome && mounted) {
        Navigator.pop(context);
        showErrorDialog(
          context,
          'Errore durante l\'eliminazione del corso',
          'Indietro',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showErrorDialog(
          context,
          'Errore durante l\'eliminazione del corso',
          'Indietro',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dettaglio corso')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_course == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text("Impossibile caricare i dati del corso."),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text("Riprova")),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CourseTypeBadge(text: _course!.type.name),
          const SizedBox(height: 24),
          CourseInfoCard(course: _course!),
          Center(
            child: TextButton(
              onPressed: () => Nav.to(
                context,
                ViewAttendees(attendees: _attendees, courseId: widget.courseId),
              ),
              child: Text(
                'Visualizza partecipanti',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () =>
                    Nav.to(context, EditCourse(courseId: widget.courseId)),
                child: const Text(
                  'MODIFICA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _deleteCourse,
                child: const Text(
                  'CANCELLA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
