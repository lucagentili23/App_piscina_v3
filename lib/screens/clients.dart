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
  final _userService = UserService();
  final _childService = ChildService();

  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUsers();
  }

  Future<void> _getUsers() async {
    try {
      final users = await _userService.getUsers();

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

  Future<void> _makeAdmin(String userId, String userName) async {
    try {
      final confirm = await showConfirmDialog(
        context,
        'Sei sicuro di voler rendere amministratore l\'utente $userName?',
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

      final outcome = await _userService.makeAdmin(userId);

      if (outcome && mounted) {
        Navigator.pop(context);
        showSuccessDialog(
          context,
          'Operazione eseguita correttamente',
          onContinue: () {
            setState(() {
              _isLoading = true;
            });
            _getUsers();
          },
        );
      }

      if (!outcome && mounted) {
        showErrorDialog(
          context,
          'Errore durante l\'esecuzione dell\'operazione',
          'Continua',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Errore durante l\'esecuzione dell\'operazione',
          'Continua',
        );
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
      await _userService.toggleUserStatus(uid);

      if (mounted) {
        Navigator.pop(context);
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
        Navigator.pop(context);
        showErrorDialog(context, 'Errore', 'Chiudi');
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
      await _userService.deleteUserAccount(uid);

      if (mounted) {
        Navigator.pop(context);
        showSuccessDialog(
          context,
          'Account eliminato definitivamente.',
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
        Navigator.pop(context);
        showErrorDialog(context, 'Errore durante l\'eliminazione', 'Chiudi');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return RefreshIndicator(
        onRefresh: _getUsers,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Text(
                    'Nessun cliente ancora registrato',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RefreshIndicator(
        onRefresh: _getUsers,
        child: ListView.builder(
          itemCount: _users.length,
          itemBuilder: (context, index) {
            return _buildUserCard(_users[index]);
          },
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final bool isDisabled = user.isDisabled;
    final Color statusColor = isDisabled ? Colors.orange : Colors.green;
    final String statusText = isDisabled ? 'DISABILITATO' : 'ABILITATO';

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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
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
                  child: Text(
                    "Errore nel caricamento dei figli",
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final children = snapshot.data ?? [];

              if (children.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Nessun figlio registrato",
                    textAlign: TextAlign.center,
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
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextButton(
                  onPressed: () => _makeAdmin(user.id, user.fullName),
                  child: const Text(
                    'Rendi amministratore',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _handleDisable(user.id, user.fullName, user.isDisabled),
                  child: user.isDisabled
                      ? const Text(
                          'Abilita',
                          style: TextStyle(color: Colors.green),
                        )
                      : const Text(
                          'Disabilita',
                          style: TextStyle(color: Colors.orange, fontSize: 16),
                        ),
                ),
                TextButton(
                  onPressed: () => _handleDelete(user.id, user.fullName),
                  child: const Text(
                    'Elimina',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
