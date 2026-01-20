import 'package:flutter/material.dart';

void showSuccessDialog(
  BuildContext context,
  String message, {
  VoidCallback? onContinue,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48.0),

        title: const Text(
          'Successo!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        content: Text(message, textAlign: TextAlign.center),

        actions: <Widget>[
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (onContinue != null) {
                  onContinue();
                }
              },
              child: const Text(
                'Continua',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],

        actionsAlignment: MainAxisAlignment.center,
      );
    },
  );
}

void showErrorDialog(
  BuildContext context,
  String message,
  String textButtonMessage,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 48.0),

        title: const Text(
          'Errore!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        content: Text(message, textAlign: TextAlign.center),

        actions: <Widget>[
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                textButtonMessage,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],

        actionsAlignment: MainAxisAlignment.center,
      );
    },
  );
}

void showAlertDialog(
  BuildContext context,
  String message,
  String textButtonMessage,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.amber, size: 48.0),

        title: const Text(
          'Attenzione!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        content: Text(message, textAlign: TextAlign.center),

        actions: <Widget>[
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                textButtonMessage,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],

        actionsAlignment: MainAxisAlignment.center,
      );
    },
  );
}

Future<bool> showConfirmDialog(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.amber, size: 48.0),
        title: const Text('Attenzione!', textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Conferma'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      );
    },
  );

  return result ?? false;
}
