import 'package:app_piscina_v3/layouts/user_layout.dart';
import 'package:app_piscina_v3/models/attendee.dart';
import 'package:app_piscina_v3/models/child.dart';
import 'package:app_piscina_v3/models/course.dart';
import 'package:app_piscina_v3/models/user_model.dart';
import 'package:app_piscina_v3/services/auth_service.dart';
import 'package:app_piscina_v3/services/child_service.dart';
import 'package:app_piscina_v3/services/course_service.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:app_piscina_v3/utils/general_utils.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
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
  final _childService = ChildService();
  Course? _course;
  UserModel? _user;
  List<Child> _children = [];
  bool _isLoading = true;
  bool _isBooking = false;

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

      if (userData != null) {
        children = await _childService.getChildren(userData.id);
      }

      setState(() {
        _course = courseData;
        _user = userData;
        _children = children;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _bookUser() async {
    setState(() {
      _isBooking = true;
    });

    List<Attendee> attendees = [];
    try {
      final attendee = Attendee(
        id: '',
        userId: _user!.id,
        displayedName: _user!.fullName,
        displayedPhotoUrl: _user!.photoUrl,
      );

      attendees.add(attendee);

      await _courseService.bookCourse(widget.courseId, attendees);

      setState(() {
        _isBooking = false;
      });

      if (mounted) {
        showSuccessDialog(
          context,
          'Prenotazione effettuata con successo!',
          onContinue: () => Nav.replace(context, const UserLayout()),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Errore durante la prenotazione al corso',
          'Continua',
        );
      }
    }
  }

  Future<void> _book(List<String> ids) async {
    try {
      setState(() {
        _isBooking = true;
      });

      List<Attendee> attendees = [];

      for (String id in ids) {
        if (id == _user!.id) {
          final attedee = Attendee(
            id: '',
            userId: _user!.id,
            displayedName: _user!.fullName,
            displayedPhotoUrl: _user!.photoUrl,
          );
          attendees.add(attedee);
        } else {
          final child = _children.firstWhere((c) => c.id == id);
          final attendee = Attendee(
            id: '',
            userId: _user!.id,
            childId: child.id,
            displayedName: child.fullName,
            displayedPhotoUrl: child.photoUrl,
          );
          attendees.add(attendee);
        }
      }

      await _courseService.bookCourse(widget.courseId, attendees);

      setState(() {
        _isBooking = false;
      });

      if (mounted) {
        showSuccessDialog(
          context,
          'Prenotazione effettuata con successo!',
          onContinue: () => Nav.replace(context, const UserLayout()),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Errore durante la prenotazione al corso',
          'Continua',
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
            child: _isBooking
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _isBooking
                        ? null
                        : _course!.isBookingOpen
                        ? _children.isEmpty
                              ? _bookUser
                              : _showBookingModalBottomSheet
                        : () => showAlertDialog(
                            context,
                            'Le prenotazioni per questo corso non sono ancora aperte',
                            'Continua',
                          ),
                    child: Text(
                      'PRENOTA POSTO',
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

  void _showBookingModalBottomSheet() {
    List<String> selectedIds = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              // Calcoliamo l'altezza in base alla tastiera o impostiamo un massimo
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Seleziona partecipanti",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        // --- SEZIONE GENITORE ---
                        CheckboxListTile(
                          secondary: const Icon(Icons.person),
                          title: Text("${_user!.firstName} (Io)"),
                          value: selectedIds.contains(_user!.id),
                          onChanged: (bool? value) {
                            setModalState(() {
                              value == true
                                  ? selectedIds.add(_user!.id)
                                  : selectedIds.remove(_user!.id);
                            });
                          },
                        ),
                        // --- SEZIONE FIGLI ---
                        ..._children.map((child) {
                          return CheckboxListTile(
                            secondary: const Icon(Icons.person),
                            title: Text(child.firstName),
                            value: selectedIds.contains(child.id),
                            onChanged: (bool? value) {
                              setModalState(() {
                                value == true
                                    ? selectedIds.add(child.id)
                                    : selectedIds.remove(child.id);
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedIds.isEmpty
                          ? null
                          : _isBooking
                          ? null
                          : () {
                              _book(selectedIds);
                              Navigator.pop(context);
                            },
                      child: Text("Prenota (${selectedIds.length})"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
