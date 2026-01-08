import 'package:app_piscina_v3/layouts/user_layout.dart';
import 'package:app_piscina_v3/models/attendee.dart';
import 'package:app_piscina_v3/models/child.dart';
import 'package:app_piscina_v3/models/user_model.dart';
import 'package:app_piscina_v3/services/course_service.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:flutter/material.dart';

class BookingModalBottomSheet extends StatefulWidget {
  final String courseId;
  final UserModel user;
  final List<Child> children;

  const BookingModalBottomSheet({
    super.key,
    required this.courseId,
    required this.user,
    required this.children,
  });

  static void show(
    BuildContext context, {
    required String courseId,
    required UserModel user,
    required List<Child> children,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BookingModalBottomSheet(
        courseId: courseId,
        user: user,
        children: children,
      ),
    );
  }

  @override
  State<BookingModalBottomSheet> createState() =>
      _BookingModalBottomSheetState();
}

class _BookingModalBottomSheetState extends State<BookingModalBottomSheet> {
  final _courseService = CourseService();
  final List<String> _selectedIds = [];
  bool _isBooking = false;

  Future<void> _book() async {
    setState(() => _isBooking = true);

    try {
      List<Attendee> attendees = [];

      for (String id in _selectedIds) {
        if (id == widget.user.id) {
          attendees.add(
            Attendee(
              id: '',
              userId: widget.user.id,
              displayedName: widget.user.fullName,
              displayedPhotoUrl: widget.user.photoUrl,
            ),
          );
        } else {
          final child = widget.children.firstWhere((c) => c.id == id);
          attendees.add(
            Attendee(
              id: '',
              userId: widget.user.id,
              childId: child.id,
              displayedName: child.fullName,
              displayedPhotoUrl: child.photoUrl,
            ),
          );
        }
      }

      await _courseService.bookCourse(widget.courseId, attendees);

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
    return Container(
      padding: const EdgeInsets.all(20),
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
                // Sezione Genitore
                CheckboxListTile(
                  secondary: const Icon(Icons.person),
                  title: Text("${widget.user.firstName} (Io)"),
                  value: _selectedIds.contains(widget.user.id),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedIds.add(widget.user.id);
                      } else {
                        _selectedIds.remove(widget.user.id);
                      }
                    });
                  },
                ),
                // Sezione Figli
                ...widget.children.map((child) {
                  return CheckboxListTile(
                    secondary: const Icon(Icons.child_care),
                    title: Text(child.firstName),
                    value: _selectedIds.contains(child.id),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(child.id);
                        } else {
                          _selectedIds.remove(child.id);
                        }
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
            child: _isBooking
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _selectedIds.isEmpty ? null : _book,
                    child: Text("Prenota (${_selectedIds.length})"),
                  ),
          ),
        ],
      ),
    );
  }
}
