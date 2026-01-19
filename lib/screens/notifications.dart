import 'package:app_piscina_v3/services/user_service.dart'; // Assicurati che il percorso sia corretto
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Notifications extends StatelessWidget {
  const Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    final user = UserService().currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Effettua il login")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifiche')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nessuna notifica'));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool isRead =
                  data['read'] ?? false; // Leggi lo stato attuale

              return ListTile(
                leading: Icon(
                  isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: isRead ? Colors.grey : Colors.blue,
                ),
                title: Text(
                  data['title'] ?? '',
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(data['body'] ?? ''),
                onTap: () {
                  if (!isRead) {
                    // Se non è letta, aggiornala sul database
                    UserService().markNotificationAsRead(doc.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
