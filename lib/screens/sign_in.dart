import 'package:app_piscina_v3/layouts/admin_layout.dart';
import 'package:app_piscina_v3/layouts/user_layout.dart';
import 'package:app_piscina_v3/screens/sign_up.dart';
import 'package:app_piscina_v3/services/auth_service.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:app_piscina_v3/utils/validators.dart';
import 'package:flutter/material.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<StatefulWidget> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _visible = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (user != null) {
        final userRole = await _authService.getUserRole();

        if (!mounted) return;

        if (userRole == UserRole.admin) {
          Nav.replace(context, AdminLayout());
        } else {
          Nav.replace(context, UserLayout());
        }
      }
    } catch (e) {
      if (e == 'user-not-found') {
        showErrorDialog(
          context,
          'L\'email o la password non coincidono',
          'Riprova',
        );
      } else if (e == 'too-many-requests') {
        showErrorDialog(
          context,
          'Troppe richieste, riprova più tardi',
          'Continua',
        );
      } else {
        showErrorDialog(context, 'Qualcosa è andato storto', 'Continua');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Accesso',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/Logo_no_bg.png', width: 200),
                      Form(
                        key: _formKey,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                validator: Validators.validateEmailSignIn,
                                decoration: InputDecoration(
                                  label: const Text('Email'),
                                  prefixIcon: Icon(Icons.email),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _passwordController,
                                validator: Validators.validatePasswordSignIn,
                                obscureText: _visible,
                                decoration: InputDecoration(
                                  label: const Text('Password'),
                                  prefixIcon: Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _visible = !_visible;
                                      });
                                    },
                                    icon: _visible
                                        ? Icon(Icons.visibility)
                                        : Icon(Icons.visibility_off),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                child: _isLoading
                                    ? CircularProgressIndicator()
                                    : ElevatedButton(
                                        onPressed: _isLoading ? null : _signIn,
                                        child: Text(
                                          'Accedi',
                                          style: TextStyle(fontSize: 20),
                                        ),
                                      ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Non hai un account?',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Nav.replace(context, SignUp()),
                                    child: const Text(
                                      'Registrati',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
