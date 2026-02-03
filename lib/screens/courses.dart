import 'package:app_piscina_v3/models/course.dart';
import 'package:app_piscina_v3/screens/course_details_admin.dart';
import 'package:app_piscina_v3/screens/course_details_user.dart';
import 'package:app_piscina_v3/screens/create_course.dart';
import 'package:app_piscina_v3/services/user_service.dart';
import 'package:app_piscina_v3/services/course_service.dart';
import 'package:app_piscina_v3/theme.dart';
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
  final _userService = UserService();
  UserRole? _role;
  List<Course> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _getCourses();
  }

  Future<void> _loadRole() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final role = await _userService.getUserRole();

      if (!mounted) return;

      if (mounted) {
        setState(() {
          _role = role;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _role = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCourses() async {
    try {
      final courses = await _courseService.getCourses();

      if (!mounted) return;

      setState(() {
        _courses = courses;
      });
    } catch (e) {
      setState(() {
        _courses = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_courses.isEmpty) {
      return RefreshIndicator(
        onRefresh: _getCourses,
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Text(
                        'Nessun corso ancora disponibile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
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
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _getCourses,
      child: Stack(
        children: [
          ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            itemCount: _courses.length,
            itemBuilder: (context, index) {
              return _buildCourseCard(_courses[index]);
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
      ),
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
                if (_role == UserRole.admin) {
                  Nav.to(context, CourseDetailsAdmin(courseId: course.id));
                } else {
                  Nav.to(context, CourseDetailsUser(courseId: course.id));
                }
              },
        child: ListTile(
          leading: Container(
            decoration: BoxDecoration(
              color: AppTheme.lightPrimaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Icon(
                course.type == CourseType.idrobike
                    ? Icons.pedal_bike_outlined
                    : Icons.pool,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          title: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          subtitle: Text(
            dateAndTimeToString(course.date),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
