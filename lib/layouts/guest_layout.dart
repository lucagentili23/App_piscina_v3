import 'package:app_piscina_v3/screens/courses.dart';
import 'package:app_piscina_v3/screens/guest_home.dart';
import 'package:flutter/material.dart';

class GuestLayout extends StatefulWidget {
  const GuestLayout({super.key});

  @override
  State<GuestLayout> createState() => _GuestLayoutState();
}

class _GuestLayoutState extends State<GuestLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [const GuestHome(), const Courses()];

  final List<String> _titles = ['Home', 'Corsi'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex]), centerTitle: true),

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
