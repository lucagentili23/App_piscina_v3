import 'package:app_piscina_v3/screens/admin_home.dart';
import 'package:app_piscina_v3/screens/clients.dart';
import 'package:app_piscina_v3/screens/courses.dart';
import 'package:flutter/material.dart';

class AdminLayout extends StatefulWidget {
  final int? index;
  const AdminLayout({super.key, this.index});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminHome(),
    const Courses(),
    const Clients(),
  ];

  final List<String> _titles = ['Home', 'Corsi', 'Clienti'];

  @override
  void initState() {
    super.initState();
    if (widget.index != null) {
      _selectedIndex = widget.index!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),

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
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clienti'),
        ],
      ),
    );
  }
}
