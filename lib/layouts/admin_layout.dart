import 'package:app_piscina_v3/screens/admin_home.dart';
import 'package:app_piscina_v3/screens/clients.dart';
import 'package:app_piscina_v3/screens/courses.dart';
import 'package:app_piscina_v3/screens/notifications.dart';
import 'package:app_piscina_v3/screens/sign_in.dart';
import 'package:app_piscina_v3/services/user_service.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:flutter/material.dart';

class AdminLayout extends StatefulWidget {
  final int? index;
  const AdminLayout({super.key, this.index});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  final _userService = UserService();
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminHome(),
    const Courses(),
    const Clients(),
  ];

  final List<String> _titles = ['Home', 'Corsi', 'Clienti'];

  void _signOut() async {
    await _userService.signOut();

    if (!mounted) return;

    Nav.replace(context, SignIn());
  }

  @override
  void initState() {
    if (widget.index != null) {
      _selectedIndex = widget.index!;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
        actions: [
          if (_selectedIndex == 0) ...[
            StreamBuilder<bool>(
              stream: _userService.unreadNotificationsStream,
              initialData: false,
              builder: (context, snapshot) {
                final hasUnread = snapshot.data ?? false;

                return IconButton(
                  onPressed: () => Nav.to(context, const Notifications()),
                  icon: hasUnread
                      ? Badge(
                          smallSize: 10,
                          isLabelVisible: true,
                          backgroundColor: Colors.red,
                          child: const Icon(Icons.notifications_outlined),
                        )
                      : const Icon(Icons.notifications_outlined),
                );
              },
            ),
            IconButton(
              onPressed: () => _signOut(),
              icon: const Icon(Icons.exit_to_app),
            ),
          ],
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
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clienti'),
        ],
      ),
    );
  }
}
