import 'package:app_piscina_v3/models/course.dart';
import 'package:app_piscina_v3/models/user_model.dart';
import 'package:app_piscina_v3/services/auth_service.dart';
import 'package:app_piscina_v3/services/course_service.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:app_piscina_v3/utils/general_utils.dart';
import 'package:app_piscina_v3/widgets/course_details/course_type_bedge.dart';
import 'package:app_piscina_v3/widgets/course_details/info_row.dart';
import 'package:flutter/material.dart';

class CourseDetailsUser extends StatefulWidget {
  final String courseId;

  const CourseDetailsUser({super.key, required this.courseId});

  @override
  State<CourseDetailsUser> createState() => _CourseDetailsUserState();
}

class _CourseDetailsUserState extends State<CourseDetailsUser> {
  final _courseService = CourseService();
  final _authService = AuthService();
  Course? _course;
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  Future<void> _loadData() async {
    try {
      final courseData = await _courseService.getCourseById(widget.courseId);
      final userData = await _authService.getUserData();

      setState(() {
        _course = courseData;
        _user = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
      return Center(child: CircularProgressIndicator());
    }

    if (_course == null || _user == null) {
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
          Card(
            elevation: 4,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  InfoRow(
                    icon: Icons.calendar_month,
                    label: "Data e Ora",
                    value: dateAndTimeToString(_course!.date),
                  ),
                  const Divider(height: 30),
                  InfoRow(
                    icon: Icons.people,
                    label: "Disponibilità",
                    value: _course!.type == CourseType.nuoto
                        ? 'Posti Illimitati'
                        : '${24 - _course!.bookedSpots} posti rimanenti',
                  ),
                  const Divider(height: 30),
                  InfoRow(
                    icon: Icons.event_available,
                    label: "Apertura Prenotazioni",
                    value: dateToString(_course!.bookingOpenDate),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {},
              /*_bookable
                          ? _user!.children.isEmpty
                                ? () => _bookUser()
                                : () => _showBookingDialog()
                          : () => showAlertDialog(
                              context,
                              'Le prenotazioni per questo corso non sono ancora aperte',
                              'Continua',
                            ),*/
              child: Text(
                'PRENOTA POSTO',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
