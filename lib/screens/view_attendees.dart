import 'package:app_piscina_v3/models/attendee.dart';
import 'package:app_piscina_v3/services/course_service.dart';
import 'package:app_piscina_v3/theme.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:flutter/material.dart';

class ViewAttendees extends StatefulWidget {
  final String courseId;
  final List<Attendee> attendees;

  const ViewAttendees({
    super.key,
    required this.attendees,
    required this.courseId,
  });

  @override
  State<ViewAttendees> createState() => _ViewAttendeesState();
}

class _ViewAttendeesState extends State<ViewAttendees> {
  final _courseService = CourseService();

  Future<void> _unbookAttendee(String attendeeId) async {
    try {
      final confirm = await showConfirmDialog(
        context,
        'Sei sicuro di voler rimuovere il partecipante selezionato dal corso?',
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

      bool outcome = false;

      outcome = await _courseService.removeAttendee(
        widget.courseId,
        attendeeId,
      );

      if (outcome && mounted) {
        Navigator.pop(context);
        showSuccessDialog(
          context,
          'Prenotazione rimossa con successo!',
          onContinue: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Errore durante la rimozione del partecipante dal corso',
          'Continua',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Partecipanti')),
      body: widget.attendees.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  'Ancora nessun partecipante per questo corso',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: widget.attendees.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundImage: AssetImage(
                                  widget.attendees[index].displayedPhotoUrl,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.attendees[index].displayedName,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () =>
                                _unbookAttendee(widget.attendees[index].id),
                            icon: Icon(
                              Icons.delete,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
