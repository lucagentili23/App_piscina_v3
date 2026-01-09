import 'package:app_piscina_v3/models/child.dart';
import 'package:app_piscina_v3/models/user_model.dart';
import 'package:app_piscina_v3/services/user_service.dart';
import 'package:app_piscina_v3/services/child_service.dart';
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

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return Center(child: Text('Nessun cliente ancora registrato'));
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
          Text('Figli'),
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

              final children = snapshot.data ?? [] as List<Child>;

              if (children.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Nessun figlio registrato",
                    style: TextStyle(fontStyle: FontStyle.italic),
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
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: () {}, child: Text('Disabilita')),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: () {}, child: Text('Elimina')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
