import 'package:app_piscina_v3/models/child.dart';
import 'package:app_piscina_v3/models/user_model.dart';
import 'package:app_piscina_v3/screens/add_child.dart';
import 'package:app_piscina_v3/services/auth_service.dart';
import 'package:app_piscina_v3/services/child_service.dart';
import 'package:app_piscina_v3/theme.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:flutter/material.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<StatefulWidget> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final _authService = AuthService();
  final _childService = ChildService();

  UserModel? _user;
  List<Child> _children = [];

  bool _isLoading = true;

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  Future<void> _loadData() async {
    try {
      final user = await _authService.getUserData();

      List<Child> children = [];

      if (user != null) {
        children = await _childService.getChildren(user.id);
      }

      setState(() {
        _user = user;
        _children = children;
        _isLoading = false;
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text("Errore durante il caricamento dei dati."),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text("Riprova")),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage(_user!.photoUrl),
              ),
              const SizedBox(height: 20),
              Text(
                _user!.gender == Gender.m
                    ? "Bentornato ${_user!.firstName}!"
                    : "Bentornata ${_user!.firstName}!",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _children.isEmpty
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Hai dei figli da iscrivere?'),
                        TextButton(
                          onPressed: () => Nav.to(context, const AddChild()),
                          child: Text('Clicca qui'),
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: AppTheme.lightSecondaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              "I tuoi figli registrati:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ..._children.map(
                              (child) => _buildChildHeader(child),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  Nav.to(context, const AddChild()),
                              icon: const Icon(Icons.add),
                              label: const Text("Aggiungi"),
                            ),
                          ],
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildHeader(Child child) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage(child.photoUrl),
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "${child.firstName} ${child.lastName}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.edit),
              color: Colors.grey[700],
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.delete),
              color: Colors.grey[700],
            ),
          ],
        ),
      ),
    );
  }
}
