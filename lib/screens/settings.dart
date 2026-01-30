import 'package:app_piscina_v3/models/user_model.dart';
import 'package:app_piscina_v3/screens/sign_in.dart';
import 'package:app_piscina_v3/services/user_service.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _userService = UserService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  void _getUserData() async {
    try {
      final user = await _userService.getUserData();

      if (user == null) {
        setState(() {
          _user = null;
        });
      } else {
        setState(() {
          _user = user;
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Errore durante il recupero dei dati',
          'Indietro',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchPrivacyUrl() async {
    final Uri url = Uri.parse(
      'https://lucagentili23.github.io/piscina-pergola-legal/',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _handleDelete(String uid, String userName) async {
    final confirm = await showConfirmDialog(
      context,
      'ATTENZIONE: Stai per eliminare definitivamente $userName.\n\nVerranno cancellati:\n- L\'account di accesso\n- I dati anagrafici\n- I figli associati\n- Tutte le prenotazioni effettuate.\n\nQuesta operazione è irreversibile.',
    );

    if (!confirm) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      await _userService.deleteUserAccount(uid);

      if (mounted) {
        Navigator.pop(context);
        showSuccessDialog(
          context,
          'Account eliminato definitivamente.',
          onContinue: () {
            setState(() {
              _isLoading = true;
            });
            Nav.replace(context, const SignIn());
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showErrorDialog(context, 'Errore durante l\'eliminazione', 'Chiudi');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              "Errore durante il caricamento dei dati",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getUserData,
              child: const Text("Riprova"),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            'Privacy policy e supporto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () => _launchPrivacyUrl(),
            child: const Text(
              'Visualizza privacy policy e supporto',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Divider(),
          Text(
            'Gestione account',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () => _handleDelete(_user!.id, _user!.fullName),
            child: const Text(
              'Elimina account',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
