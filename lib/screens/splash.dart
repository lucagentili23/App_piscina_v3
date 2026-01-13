import 'package:app_piscina_v3/layouts/admin_layout.dart';
import 'package:app_piscina_v3/layouts/user_layout.dart';
import 'package:app_piscina_v3/screens/sign_in.dart';
import 'package:app_piscina_v3/services/user_service.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<StatefulWidget> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  final _authService = UserService();

  @override
  void initState() {
    super.initState();
    _splash();
  }

  void _splash() async {
    await Future.delayed(const Duration(seconds: 1));

    try {
      final user = FirebaseAuth.instance.currentUser;
      final authService = UserService();

      if (user != null) {
        try {
          await user.reload();

          final userRole = await authService.getUserRole();

          if (!mounted) return;

          if (userRole == UserRole.admin) {
            Nav.replace(context, AdminLayout());
          } else {
            Nav.replace(context, UserLayout());
          }
        } catch (e) {
          await _authService.signOut();

          if (!mounted) return;

          Nav.replace(context, SignIn());
        }
      } else {
        if (mounted) {
          Nav.replace(context, SignIn());
        }
      }
    } catch (e) {
      if (mounted) {
        Nav.replace(context, SignIn());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/Logo_no_bg.png',
              height: 150,
              width: 150,
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
