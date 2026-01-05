import 'package:flutter/material.dart';

class Nav {
  static void replace(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => screen),
      (Route<dynamic> route) => false,
    );
  }

  static void to(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  static void back(BuildContext context) {
    Navigator.of(context).pop();
  }
}
