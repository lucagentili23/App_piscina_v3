import 'package:app_piscina_v3/models/course.dart';
import 'package:app_piscina_v3/screens/course_details_admin.dart';
import 'package:app_piscina_v3/screens/course_details_user.dart';
import 'package:app_piscina_v3/screens/create_course.dart';
import 'package:app_piscina_v3/services/user_service.dart';
import 'package:app_piscina_v3/services/course_service.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:app_piscina_v3/utils/general_utils.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:flutter/material.dart';

class Courses extends StatefulWidget {
  const Courses({super.key});

  @override
  State<StatefulWidget> createState() => _CoursesState();
}

class _CoursesState extends State<Courses> {
  final _courseService = CourseService();
  final _authService = UserService();
  UserRole? _role;
  bool _isLoading = true;

  @override
  void initState() {
    _loadRole();
    super.initState();
  }

  Future<void> _loadRole() async {
    final role = await _authService.getUserRole();
    if (mounted) {
      setState(() {
        _role = role;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<List<Course>>(
          stream: _courseService.getCoursesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Errore durante il caricamento dei corsi',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            final courses = snapshot.data ?? [];

            if (courses.isEmpty) {
              return Center(
                child: Text(
                  'Nessun corso ancora disponibile',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                return _buildCourseCard(courses[index]);
              },
            );
          },
        ),
        if (_role == UserRole.admin)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Nav.to(context, CreateCourse());
              },
              elevation: 6,
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  Widget _buildCourseCard(Course course) {
    final String title =
        course.type.name[0].toUpperCase() + course.type.name.substring(1);

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _isLoading
            ? null
            : () {
                Nav.to(
                  context,
                  _role == UserRole.admin
                      ? CourseDetailsAdmin(courseId: course.id)
                      : CourseDetailsUser(courseId: course.id),
                );
              },
        child: ListTile(
          leading: Container(
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: course.type == CourseType.idrobike
                  ? Icon(Icons.pedal_bike_outlined)
                  : Icon(Icons.pool),
            ),
          ),
          title: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          subtitle: Text(
            dateAndTimeToString(course.date),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
