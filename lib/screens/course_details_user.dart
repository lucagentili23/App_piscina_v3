import 'package:app_piscina_v3/layouts/user_layout.dart';
import 'package:app_piscina_v3/models/attendee.dart';
import 'package:app_piscina_v3/models/child.dart';
import 'package:app_piscina_v3/models/course.dart';
import 'package:app_piscina_v3/models/user_model.dart';
import 'package:app_piscina_v3/screens/sign_in.dart';
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

  List<Attendee> _attendees = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final courseFuture = _courseService.getCourseById(widget.courseId);
      final userFuture = _authService.getUserData();

      final results = await Future.wait([courseFuture, userFuture]);

      final courseData = results[0] as Course?;
      final userData = results[1] as UserModel?;

      List<Child> children = [];
      bool isBooked = false;
      List<Attendee> attendees = [];

      if (userData != null) {
        final childrenFuture = _childService.getChildren(userData.id);
        final isBookedFuture = _courseService.isBooked(
          userData.id,
          widget.courseId,
        );
        final attendeesFuture = _courseService.getCourseAttendeesForUser(
          widget.courseId,
          userData.id,
        );

        final secondaryResults = await Future.wait([
          childrenFuture,
          isBookedFuture,
          attendeesFuture,
        ]);

        children = secondaryResults[0] as List<Child>;
        isBooked = secondaryResults[1] as bool;
        attendees = secondaryResults[2] as List<Attendee>;
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

  Future<void> _handleForcedLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignIn()),
        (route) => false,
      );
    }
  }

  Future<void> _unbook(String attendeeDocId) async {
    try {
      final confirm = await showConfirmDialog(
        context,
        'Sei sicuro di voler cancellare la prenotazione?',
      );

      if (!confirm) return;

      final isAllowed = await _authService.canUserDoIt();
      if (!isAllowed) {
        await _handleForcedLogout();
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final outcome = await _courseService.removeAttendee(
        widget.courseId,
        attendeeDocId,
      );

      if (outcome && mounted) {
        Nav.replace(context, const UserLayout());
      }

      if (!outcome && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        showErrorDialog(context, 'Errore durante la cancellazione', 'Indietro');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        showErrorDialog(context, 'Errore durante la cancellazione', 'Indietro');
      }
    }
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

      final outcome = await _courseService.bookCourse(widget.courseId, [
        attendee,
      ]);

      if (outcome && mounted) {
        showSuccessDialog(
          context,
          'Prenotazione effettuata con successo!',
          onContinue: () => Nav.replace(context, const UserLayout()),
        );
      }

      if (!outcome && mounted) {
        showErrorDialog(context, 'Errore durante la prenotazione', 'Indietro');
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'Errore durante la prenotazione', 'Indietro');
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
            const Text(
              "Impossibile caricare i dati del corso.",
              textAlign: TextAlign.center,
            ),
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
          const SizedBox(height: 20),
          CourseInfoCard(course: _course!),
          if (_attendees.isNotEmpty && _children.isNotEmpty) ...[
            const SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.lightPrimaryColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.assignment_turned_in,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Le tue iscrizioni:',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
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
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: AssetImage(
                                        attendee.displayedPhotoUrl,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      attendee.displayedName,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed:
                                      DateTime.now().isBefore(
                                        _course!.date.subtract(
                                          Duration(hours: 6),
                                        ),
                                      )
                                      ? () => _unbook(attendee.id)
                                      : () => showAlertDialog(
                                          context,
                                          'Non è possibile cancellare la prenotazione nelle 8 ore precedenti il corso',
                                          'Indietro',
                                        ),
                                  child: Text('Rimuovi'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed: _handleBookingPress,
                        child: Text(
                          'AGGIUNGI PRENOTAZIONE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (_attendees.isEmpty && _children.isEmpty)
            Center(
              child: _isBooking
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _isBooked ? null : _handleBookingPress,
                      child: Text(
                        'PRENOTA POSTO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          if (_attendees.isEmpty && _children.isNotEmpty)
            Center(
              child: _isBooking
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _isBooked ? null : _handleBookingPress,
                      child: Text(
                        'PRENOTA POSTO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          if (_attendees.isNotEmpty && _children.isEmpty)
            Center(
              child: _isBooking
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed:
                          DateTime.now().isBefore(
                            _course!.date.subtract(Duration(hours: 6)),
                          )
                          ? () => _unbook(_attendees[0].id)
                          : () => showAlertDialog(
                              context,
                              'Non è possibile cancellare la prenotazione nelle 8 ore precedenti il corso',
                              'Indietro',
                            ),
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

  Future<void> _handleBookingPress() async {
    if (_isBooking) return;

    final isAllowed = await _authService.canUserDoIt();
    if (!isAllowed) {
      await _handleForcedLogout();
      return;
    }

    if (_attendees.length == _children.length + 1) {
      if (mounted) {
        showAlertDialog(
          context,
          'Sia tu che tutti i tuoi figli siete già iscritti a questo corso',
          'Continua',
        );
      }
      return;
    }

    if (!_course!.isBookingOpen) {
      if (mounted) {
        showAlertDialog(
          context,
          'Le prenotazioni per questo corso non sono ancora aperte',
          'Continua',
        );
      }
      return;
    }

    if (_course!.maxSpots != null) {
      if (_course!.bookedSpots == _course!.maxSpots) {
        if (mounted) {
          showAlertDialog(
            context,
            'Non sono più disponibili posti per questo corso',
            'Indietro',
          );
        }
        return;
      }
    }

    if (_children.isEmpty) {
      await _bookUserDirectly();
    } else {
      if (mounted) {
        BookingModalBottomSheet.show(
          context,
          courseId: widget.courseId,
          user: _user!,
          children: _children,
          bookedAttendees: _attendees,
        );
      }
    }
  }
}
