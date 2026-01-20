import 'package:app_piscina_v3/services/user_service.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  final _userService = UserService();

  Future<void> deleteNotification(String id) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final outcome = await _userService.deleteNotification(id);

      if (!outcome && mounted) {
        Navigator.pop(context);
        showErrorDialog(
          context,
          'Errore durante l\'eliminazione della notifica',
          'Indietro',
        );
        return;
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showErrorDialog(
          context,
          'Errore durante l\'eliminazione della notifica',
          'Indietro',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    if (userService.currentUser == null) {
      return const Scaffold(body: Center(child: Text("Effettua il login")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifiche')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userService.currentUser!.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Errore durante il caricamento delle notifiche',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nessuna notifica', textAlign: TextAlign.center),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool isRead = data['read'] ?? false;

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
                    userService.markNotificationAsRead(doc.id);
                  }
                },
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => deleteNotification(doc.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
