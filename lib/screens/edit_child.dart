import 'package:app_piscina_v3/layouts/user_layout.dart';
import 'package:app_piscina_v3/models/child.dart';
import 'package:app_piscina_v3/services/child_service.dart';
import 'package:app_piscina_v3/services/user_service.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:app_piscina_v3/utils/validators.dart';
import 'package:flutter/material.dart';

class EditChild extends StatefulWidget {
  final String childId;
  const EditChild({super.key, required this.childId});

  @override
  State<EditChild> createState() => _EditChildState();
}

class _EditChildState extends State<EditChild> {
  final _userService = UserService();
  final _childService = ChildService();

  Child? _child;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();

  Gender _selectedValue = Gender.m;

  List<DropdownMenuEntry<Gender>> sexEntries = [
    DropdownMenuEntry(value: Gender.m, label: "Maschio"),
    DropdownMenuEntry(value: Gender.f, label: "Femmina"),
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _getChildData();
    super.initState();
  }

  Future<void> _getChildData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final child = await _childService.getChildById(
        _userService.currentUser!.uid,
        widget.childId,
      );

      setState(() {
        _child = child;
        _nameController.text = child!.firstName;
        _lastNameController.text = child.lastName;
        _selectedValue = child.gender;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _child = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editChild() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

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

      final outcome = await _childService.editChild(
        _userService.currentUser!.uid,
        _child!.id,
        firstName,
        lastName,
        photoUrl,
        _selectedValue,
      );

      if (outcome && mounted) {
        showSuccessDialog(
          context,
          'Dati modificati con successo!',
          onContinue: () => Nav.replace(context, const UserLayout()),
        );
      }

      if (!outcome && mounted) {
        showErrorDialog(
          context,
          'Errore durante la modifica dei dati',
          'Continua',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Errore durante la modifica dei dati',
          'Continua',
        );
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
      appBar: AppBar(title: Text('Modifica figlio')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
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
                      initialValue: _child!.gender,
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
                              onPressed: _isLoading ? null : _editChild,
                              child: Text(
                                'Modifica',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
