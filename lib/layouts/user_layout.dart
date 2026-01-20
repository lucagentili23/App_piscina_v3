import 'package:app_piscina_v3/screens/courses.dart';
import 'package:app_piscina_v3/screens/notifications.dart';
import 'package:app_piscina_v3/screens/sign_in.dart';
import 'package:app_piscina_v3/screens/user_home.dart';
import 'package:app_piscina_v3/services/user_service.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:flutter/material.dart';

class UserLayout extends StatefulWidget {
  const UserLayout({super.key});

  @override
  State<UserLayout> createState() => _UserLayoutState();
}

class _UserLayoutState extends State<UserLayout> {
  final _userService = UserService();
  int _selectedIndex = 0;

  final List<Widget> _screens = [const UserHome(), const Courses()];

  final List<String> _titles = ['Home', 'Corsi'];

  void _signOut() async {
    final confirm = await showConfirmDialog(
      context,
      'Vuoi davvero effettuare il logout?\nDovrai accedere nuovamente con email e password',
    );

    if (!confirm) return;

    final success = await _userService.signOut();

    if (!mounted) return;

    if (success) {
      Nav.replace(context, const SignIn());
    } else {
      showErrorDialog(context, 'Errore durante il logout', 'Indietro');
    }
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
        ],
      ),
    );
  }
}
