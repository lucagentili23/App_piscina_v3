import 'package:app_piscina_v3/layouts/user_layout.dart';
import 'package:app_piscina_v3/screens/sign_in.dart';
import 'package:app_piscina_v3/services/auth_service.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:app_piscina_v3/utils/validators.dart';
import 'package:flutter/material.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<StatefulWidget> createState() => _SigupState();
}

class _SigupState extends State<SignUp> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailConfirmationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  bool _isLoading = false;
  Gender _selectedValue = Gender.m;
  bool _visible1 = true;
  bool _visible2 = true;

  List<DropdownMenuEntry<Gender>> sexEntries = [
    DropdownMenuEntry(value: Gender.m, label: "Maschio"),
    DropdownMenuEntry(value: Gender.f, label: "Femmina"),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _emailConfirmationController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final name =
        (_nameController.text[0].toUpperCase() +
                _nameController.text.substring(1))
            .trim();
    final lastName =
        (_lastNameController.text[0].toUpperCase() +
                _lastNameController.text.substring(1))
            .trim();

    try {
      final user = await _authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        name: name,
        lastName: lastName,
        gender: _selectedValue,
        role: UserRole.user,
      );

      if (!mounted) return;

      if (user != null) {
        showSuccessDialog(
          context,
          'Account creato con successo!',
          onContinue: () {
            Nav.replace(context, UserLayout());
          },
        );
      }
    } catch (e) {
      if (!mounted) return;

      if (e == 'email-already-in-use') {
        showErrorDialog(
          context,
          'Questa email è già associata ad un altro account',
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
          'Registrazione',
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
                                controller: _nameController,
                                validator: Validators.validateName,
                                decoration: InputDecoration(
                                  label: const Text('Nome'),
                                  prefixIcon: Icon(Icons.account_circle),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _lastNameController,
                                validator: Validators.validateName,
                                decoration: InputDecoration(
                                  label: const Text('Cognome'),
                                  prefixIcon: Icon(Icons.account_circle),
                                ),
                              ),

                              const SizedBox(height: 20),
                              DropdownButtonFormField<Gender>(
                                decoration: const InputDecoration(
                                  labelText: "Sesso",
                                ),
                                initialValue: _selectedValue,
                                items: sexEntries
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e.value,
                                        child: Text(e.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    if (value != null) {
                                      _selectedValue = value;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _emailController,
                                validator: Validators.validateEmail,
                                decoration: InputDecoration(
                                  label: const Text('Email'),
                                  prefixIcon: Icon(Icons.email),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _emailConfirmationController,
                                validator: (value) =>
                                    Validators.validateConfirmEmail(
                                      value,
                                      _emailController.text,
                                    ),
                                decoration: InputDecoration(
                                  label: const Text('Conferma email'),
                                  prefixIcon: Icon(Icons.email),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _passwordController,
                                validator: Validators.validatePassword,
                                obscureText: _visible1,
                                decoration: InputDecoration(
                                  label: const Text('Password'),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _visible1 = !_visible1;
                                      });
                                    },
                                    icon: _visible1
                                        ? Icon(Icons.visibility)
                                        : Icon(Icons.visibility_off),
                                  ),
                                  prefixIcon: Icon(Icons.lock),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _passwordConfirmationController,
                                validator: (value) =>
                                    Validators.validateConfirmPassword(
                                      value,
                                      _passwordController.text,
                                    ),
                                obscureText: _visible2,
                                decoration: InputDecoration(
                                  label: const Text('Conferma Password'),
                                  prefixIcon: Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _visible2 = !_visible2;
                                      });
                                    },
                                    icon: _visible2
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
                                        onPressed: _isLoading ? null : _signUp,
                                        child: Text(
                                          'Registrati',
                                          style: TextStyle(fontSize: 20),
                                        ),
                                      ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Hai già un account?',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Nav.replace(context, SignIn()),
                                    child: const Text(
                                      'Accedi',
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
