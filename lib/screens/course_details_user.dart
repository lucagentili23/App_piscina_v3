import 'package:app_piscina_v3/layouts/user_layout.dart';
import 'package:app_piscina_v3/models/attendee.dart';
import 'package:app_piscina_v3/models/child.dart';
import 'package:app_piscina_v3/models/course.dart';
import 'package:app_piscina_v3/models/user_model.dart';
import 'package:app_piscina_v3/services/user_service.dart';
import 'package:app_piscina_v3/services/child_service.dart';
import 'package:app_piscina_v3/services/course_service.dart';
import 'package:app_piscina_v3/theme.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:app_piscina_v3/widgets/course_details/booking_modal_bottom_sheet.dart';
import 'package:app_piscina_v3/widgets/course_details/course_info_card.dart';
import 'package:app_piscina_v3/widgets/course_details/course_type_bedge.dart';
import 'package:flutter/material.dart';

class CourseDetailsUser extends StatefulWidget {
  final String courseId;

  const CourseDetailsUser({super.key, required this.courseId});

  @override
  State<CourseDetailsUser> createState() => _CourseDetailsUserState();
}

class _CourseDetailsUserState extends State<CourseDetailsUser> {
  final _courseService = CourseService();
  final _authService = UserService();
  final _childService = ChildService();

  Course? _course;
  UserModel? _user;
  List<Child> _children = [];
  bool _isLoading = true;
  bool _isBooking = false;
  bool _isBooked = false;

  List<Map<String, dynamic>> _attendees = [];

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  Future<void> _loadData() async {
    try {
      final courseData = await _courseService.getCourseById(widget.courseId);
      final userData = await _authService.getUserData();
      List<Child> children = [];
      bool isBooked = false;
      List<Map<String, dynamic>> attendees = [];

      if (userData != null) {
        children = await _childService.getChildren(userData.id);
        isBooked = await _courseService.isBooked(userData.id, widget.courseId);
        attendees = await _courseService.getCourseAttendeesForUser(
          widget.courseId,
          userData.id,
        );
      }

      if (mounted) {
        setState(() {
          _course = courseData;
          _user = userData;
          _children = children;
          _isBooked = isBooked;
          _attendees = attendees;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unbookUserDirectly() async {
    setState(() {
      _isBooking = true;
    });

    try {
      await _courseService.unbookUserWithoutChildrenFromCourse(
        widget.courseId,
        _user!.id,
      );

      if (mounted) {
        showSuccessDialog(
          context,
          'Prenotazione cancellata con successo!',
          onContinue: () => Nav.replace(context, const UserLayout()),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Errore durante la cancellazione della prenotazione',
          'Continua',
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  Future<void> _unbook(String id, bool isUser) async {
    try {
      await _courseService.unbookFromCourse(widget.courseId, id, isUser);
    } catch (e) {}
  }

  Future<void> _bookUserDirectly() async {
    setState(() => _isBooking = true);

    try {
      final attendee = Attendee(
        id: '',
        userId: _user!.id,
        displayedName: _user!.fullName,
        displayedPhotoUrl: _user!.photoUrl,
      );

      await _courseService.bookCourse(widget.courseId, [attendee]);

      if (mounted) {
        showSuccessDialog(
          context,
          'Prenotazione effettuata con successo!',
          onContinue: () => Nav.replace(context, const UserLayout()),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'Errore durante la prenotazione', 'Continua');
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dettaglio corso')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
          CourseInfoCard(course: _course!),
          if (_attendees.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.lightSecondaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Text(
                      'Le tue iscrizioni:',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _attendees.length,
                      itemBuilder: (context, index) {
                        final attendee = _attendees[index];

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(attendee['displayName']),
                                IconButton(
                                  onPressed: attendee['isChild']
                                      ? () => _unbook(attendee['id'], false)
                                      : () => _unbook(attendee['id'], true),
                                  icon: Icon(Icons.delete),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Center(
            child: _isBooking
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _isBooked
                        ? _handleUnbookingPress
                        : _handleBookingPress,
                    child: Text(
                      _isBooked ? 'CANCELLA PRENOTAZIONE' : 'PRENOTA POSTO',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _handleBookingPress() {
    if (_isBooking) return;

    if (!_course!.isBookingOpen) {
      showAlertDialog(
        context,
        'Le prenotazioni per questo corso non sono ancora aperte',
        'Continua',
      );
      return;
    }

    if (_children.isEmpty) {
      _bookUserDirectly();
    } else {
      BookingModalBottomSheet.show(
        context,
        courseId: widget.courseId,
        user: _user!,
        children: _children,
      );
    }
  }

  void _handleUnbookingPress() {
    if (_isBooking) return;

    if (_children.isEmpty) {
      _unbookUserDirectly();
    } else {
      BookingModalBottomSheet.show(
        context,
        courseId: widget.courseId,
        user: _user!,
        children: _children,
      );
    }
  }
}
