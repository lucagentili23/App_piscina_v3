import 'package:app_piscina_v3/models/child.dart';
import 'package:app_piscina_v3/models/user_model.dart';
import 'package:app_piscina_v3/services/user_service.dart';
import 'package:app_piscina_v3/services/child_service.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:flutter/material.dart';

class Clients extends StatefulWidget {
  const Clients({super.key});

  @override
  State<StatefulWidget> createState() => _ClientsState();
}

class _ClientsState extends State<Clients> {
  final _authService = UserService();
  final _childService = ChildService();

  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    _getUsers();
    super.initState();
  }

  Future<void> _getUsers() async {
    try {
      final users = await _authService.getUsers();

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDisable(
    String uid,
    String userName,
    bool isDisabled,
  ) async {
    final confirm = await showConfirmDialog(
      context,
      isDisabled
          ? 'Sei sicuro di voler abilitare l\'utente $userName? Da questo momento sarà in grado di accedere all\'app.'
          : 'Sei sicuro di voler disabilitare l\'utente $userName? Non potrà più accedere all\'app.',
    );

    if (!confirm) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      await _authService.toggleUserStatus(uid);

      if (mounted) {
        Navigator.pop(context); // Chiude il loader
        showSuccessDialog(
          context,
          isDisabled
              ? 'Utente $userName abilitato con successo.'
              : 'Utente $userName disabilitato con successo.',
          onContinue: () {
            setState(() {
              _isLoading = true;
            });
            _getUsers();
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Chiude il loader
        showErrorDialog(context, 'Errore: $e', 'Chiudi');
      }
    }
  }

  Future<void> _handleDelete(String uid, String userName) async {
    final confirm = await showConfirmDialog(
      context,
      'ATTENZIONE: Stai per eliminare definitivamente $userName.\n\nVerranno cancellati:\n- L\'account di accesso\n- I dati anagrafici\n- I figli associati\n- Tutte le prenotazioni effettuate.\n\nQuesta operazione è irreversibile.',
    );

    if (!confirm) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      await _authService.deleteUserAccount(uid);

      if (mounted) {
        Navigator.pop(context); // Chiudi loader
        showSuccessDialog(
          context,
          'Account eliminato definitivamente.',
          onContinue: () {
            // Ricarichiamo la lista per far sparire l'utente eliminato
            setState(() {
              _isLoading = true;
            });
            _getUsers();
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Chiudi loader
        showErrorDialog(
          context,
          'Errore durante l\'eliminazione: $e',
          'Chiudi',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return const Center(child: Text('Nessun cliente ancora registrato'));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          return _buildUserCard(_users[index]);
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      elevation: 4,
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage(user.photoUrl),
          backgroundColor: Colors.grey[200],
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: const Divider(),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text('Figli', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          FutureBuilder<List<Child>>(
            future: _childService.getChildren(user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Errore nel caricamento dei figli"),
                );
              }

              final children = snapshot.data ?? [];

              if (children.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Nessun figlio registrato",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return Column(
                children: children.map((child) {
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 15,
                      backgroundImage: AssetImage(child.photoUrl),
                    ),
                    title: Text(child.fullName),
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                  );
                }).toList(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user.isDisabled
                        ? Colors.green
                        : Colors.orange,
                  ),
                  onPressed: () =>
                      _handleDisable(user.id, user.fullName, user.isDisabled),
                  child: user.isDisabled
                      ? const Text('Abilita')
                      : const Text('Disabilita'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => _handleDelete(user.id, user.fullName),
                  child: const Text('Elimina'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
