import 'package:app_piscina_v3/models/user_model.dart';
import 'package:app_piscina_v3/services/auth_service.dart';
import 'package:flutter/material.dart';

class Clients extends StatefulWidget {
  const Clients({super.key});

  @override
  State<StatefulWidget> createState() => _ClientsState();
}

class _ClientsState extends State<Clients> {
  final _authService = AuthService();

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
          // Qui devo mostrare i figli
        ],
      ),
    );
  }
}
