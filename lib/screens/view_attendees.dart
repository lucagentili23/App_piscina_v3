import 'package:app_piscina_v3/models/attendee.dart';
import 'package:app_piscina_v3/theme.dart';
import 'package:flutter/material.dart';

class ViewAttendees extends StatelessWidget {
  final List<Attendee> attendees;

  const ViewAttendees({super.key, required this.attendees});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Partecipanti')),
      body: attendees.isEmpty
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
          : ListView.builder(
              itemCount: attendees.length,
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
                                attendees[index].displayedPhotoUrl,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              attendees[index].displayedName,
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () {},
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
    );
  }
}
