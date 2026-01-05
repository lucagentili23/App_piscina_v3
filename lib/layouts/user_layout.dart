import 'package:app_piscina_v3/screens/courses.dart';
import 'package:app_piscina_v3/screens/sign_in.dart';
import 'package:app_piscina_v3/screens/user_home.dart';
import 'package:app_piscina_v3/services/auth_service.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:flutter/material.dart';

class UserLayout extends StatefulWidget {
  const UserLayout({super.key});

  @override
  State<UserLayout> createState() => _UserLayoutState();
}

class _UserLayoutState extends State<UserLayout> {
  final _authService = AuthService();
  int _selectedIndex = 0;

  final List<Widget> _screens = [const UserHome(), const Courses()];

  final List<String> _titles = ['Home', 'Corsi'];

  void _signOut() async {
    await _authService.signOut();

    if (!mounted) return;

    Nav.replace(context, SignIn());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              onPressed: () => _signOut(),
              icon: Icon(Icons.exit_to_app),
            ),
        ],
      ),

      // Cambia pagina senza distruggerla
      body: IndexedStack(index: _selectedIndex, children: _screens),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Corsi'),
        ],
      ),
    );
  }
}
