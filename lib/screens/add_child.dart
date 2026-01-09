import 'package:app_piscina_v3/layouts/user_layout.dart';
import 'package:app_piscina_v3/models/child.dart';
import 'package:app_piscina_v3/services/user_service.dart';
import 'package:app_piscina_v3/services/child_service.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:app_piscina_v3/utils/validators.dart';
import 'package:flutter/material.dart';

class AddChild extends StatefulWidget {
  const AddChild({super.key});

  @override
  State<StatefulWidget> createState() => _AddChildState();
}

class _AddChildState extends State<AddChild> {
  final _authService = UserService();
  final _chilService = ChildService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLoading = false;
  Gender _selectedValue = Gender.m;

  List<DropdownMenuEntry<Gender>> sexEntries = [
    DropdownMenuEntry(value: Gender.m, label: "Maschio"),
    DropdownMenuEntry(value: Gender.f, label: "Femmina"),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _addChild() async {
    setState(() {
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) return;

    try {
      final photoUrl = _selectedValue == Gender.m
          ? 'assets/images/Immagine_profilo_m.png'
          : 'assets/images/Immagine_profilo_f.png';

      final firstName =
          (_nameController.text[0].toUpperCase() +
                  _nameController.text.substring(1))
              .trim();
      final lastName =
          (_lastNameController.text[0].toUpperCase() +
                  _lastNameController.text.substring(1))
              .trim();

      final child = Child(
        id: '',
        firstName: firstName,
        lastName: lastName,
        photoUrl: photoUrl,
        gender: _selectedValue,
      );

      await _chilService.addChild(_authService.currentUser!.uid, child);

      if (mounted) {
        showSuccessDialog(
          context,
          'Registrazione avvenuta con successo!',
          onContinue: () => Nav.replace(context, const UserLayout()),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'Errore durante la registrazione', 'Continua');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Aggiungi figlio')),
      body: Form(
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
                decoration: const InputDecoration(labelText: "Sesso"),
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
              SizedBox(
                child: _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _isLoading ? null : _addChild,
                        child: Text('Registra', style: TextStyle(fontSize: 20)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
