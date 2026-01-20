import 'package:app_piscina_v3/services/course_service.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:app_piscina_v3/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateCourse extends StatefulWidget {
  const CreateCourse({super.key});

  @override
  State<StatefulWidget> createState() => _CreateCourseState();
}

class _CreateCourseState extends State<CreateCourse> {
  final _courseService = CourseService();
  final _formKey = GlobalKey<FormState>();

  CourseType _selectedValue = CourseType.idrobike;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  List<DropdownMenuEntry<CourseType>> eventTypeEntries = [
    DropdownMenuEntry(value: CourseType.idrobike, label: "Idrobike"),
    DropdownMenuEntry(value: CourseType.nuoto, label: "Nuoto"),
  ];

  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        final now = DateTime.now();
        final tempDate = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        _timeController.text = DateFormat('HH:mm').format(tempDate);
      });
    }
  }

  void _createCourse() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final DateTime finalDatetime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final outcome = await _courseService.createCourse(
        courseType: _selectedValue,
        date: finalDatetime,
      );

      if (outcome && mounted) {
        showSuccessDialog(
          context,
          'Corso creato correttamente',
          onContinue: () => Nav.back(context),
        );
      }

      if (!outcome && mounted) {
        showErrorDialog(
          context,
          'Errore durante la creazione del corso',
          'Indietro',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Errore durante la creazione del corso',
          'Indietro',
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
      appBar: AppBar(title: Text('Crea corso')),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    DropdownButtonFormField<CourseType>(
                      decoration: const InputDecoration(
                        labelText: "Tipologia corso",
                      ),
                      initialValue: _selectedValue,
                      items: eventTypeEntries
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
                      controller: _dateController,
                      readOnly: true,
                      validator: Validators.validateDate,
                      decoration: const InputDecoration(
                        labelText: "Data",
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context),
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _timeController,
                      readOnly: true,
                      validator: Validators.validateTime,
                      decoration: const InputDecoration(
                        labelText: "Orario",
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () => _selectTime(context),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createCourse,
                      child: _isLoading
                          ? CircularProgressIndicator()
                          : Text('Crea', style: TextStyle(fontSize: 20)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
