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
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _splash();
  }

  void _splash() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        final userService = UserService();

        if (user != null) {
          try {
            await user.reload();
            final userRole = await userService.getUserRole();

            if (!mounted) return;

            if (userRole == UserRole.admin) {
              Nav.replace(context, const AdminLayout());
            } else {
              Nav.replace(context, const UserLayout());
            }
          } catch (e) {
            await _userService.signOut();
            if (!mounted) return;
            Nav.replace(context, const SignIn());
          }
        } else {
          if (mounted) {
            Nav.replace(context, const SignIn());
          }
        }
      } catch (e) {
        debugPrint(e.toString());
        if (mounted) {
          Nav.replace(context, const SignIn());
        }
      }
    });
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
