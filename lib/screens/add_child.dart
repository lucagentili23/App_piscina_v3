import 'package:app_piscina_v3/layouts/user_layout.dart';
import 'package:app_piscina_v3/models/child.dart';
import 'package:app_piscina_v3/screens/sign_in.dart';
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
  final _userService = UserService();
  final _childService = ChildService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();

  Gender _selectedValue = Gender.m;

  List<DropdownMenuEntry<Gender>> sexEntries = [
    DropdownMenuEntry(value: Gender.m, label: "Maschio"),
    DropdownMenuEntry(value: Gender.f, label: "Femmina"),
    DropdownMenuEntry(value: Gender.x, label: "Preferisco non dirlo"),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _addChild() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final isAllowed = await _userService.canUserDoIt();

      if (!isAllowed) {
        if (mounted) {
          Navigator.pop(context);

          await _userService.signOut();

          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const SignIn()),
              (route) => false,
            );
          }
        }
        return;
      }

      String photoUrl;

      switch (_selectedValue) {
        case Gender.m:
          photoUrl = 'assets/images/Immagine_profilo_m.png';
          break;
        case Gender.f:
          photoUrl = 'assets/images/Immagine_profilo_f.png';
          break;
        default:
          photoUrl = 'assets/images/Immagine_profilo_x.png';
      }

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

      final outcome = await _childService.addChild(
        _userService.currentUser!.uid,
        child,
      );

      if (mounted) {
        Navigator.pop(context);

        if (outcome) {
          showSuccessDialog(
            context,
            'Registrazione avvenuta con successo!',
            onContinue: () => Nav.replace(context, const UserLayout()),
          );
        } else {
          showErrorDialog(
            context,
            'Errore durante la registrazione',
            'Indietro',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showErrorDialog(context, 'Errore imprevisto', 'Indietro');
      }
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
                child: ElevatedButton(
                  onPressed: _addChild,
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
