import 'package:intl/intl.dart';

String capitalize(String input) {
  input = input.trim();
  if (input.isEmpty) return '';
  return input[0].toUpperCase() + input.substring(1).toLowerCase();
}

final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

String dateAndTimeToString(DateTime date) {
  return DateFormat('dd/MM/yyyy - HH:mm').format(date);
}

String dateToString(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}
