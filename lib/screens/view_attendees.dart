import 'package:app_piscina_v3/layouts/user_layout.dart';
import 'package:app_piscina_v3/models/attendee.dart';
import 'package:app_piscina_v3/services/course_service.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
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

      final outcome = await _courseService.removeAttendee(
        widget.courseId,
        attendeeId,
      );

      if (outcome && mounted) {
        Navigator.pop(context);
        showSuccessDialog(
          context,
          'Prenotazione rimossa con successo!',
          onContinue: () => Nav.replace(context, const UserLayout()),
        );
      }

      if (!outcome && mounted) {
        showErrorDialog(
          context,
          'Errore durante la rimozione del partecipante dal corso',
          'Indietro',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Errore durante la rimozione del partecipante dal corso',
          'Indietro',
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
                  final attendee =
                      widget.attendees[index]; // Comodo per pulire il codice

                  return Card(
                    // Aggiunto margin per separare le card visivamente (opzionale ma consigliato)
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10), // Padding interno
                      child: Row(
                        children: [
                          // 1. AVATAR (Dimensione fissa)
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: AssetImage(
                              attendee.displayedPhotoUrl,
                            ),
                          ),
                          const SizedBox(width: 15),

                          // 2. NOME (Flessibile - Si prende lo spazio rimanente)
                          Expanded(
                            child: Text(
                              attendee.displayedName,
                              style: const TextStyle(fontSize: 16),
                              // Di default il Text va a capo se non c'è spazio.
                              // Se volessi troncarlo coi puntini: overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // 3. BOTTONE (Dimensione fissa in base al testo)
                          TextButton(
                            // Aggiungi un minimo di padding al bottone per evitare tocchi accidentali
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: const Size(
                                50,
                                36,
                              ), // Rende il tap target adeguato
                            ),
                            onPressed: () => _unbookAttendee(attendee.id),
                            child: const Text('Rimuovi'),
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
