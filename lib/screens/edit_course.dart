import 'package:app_piscina_v3/layouts/admin_layout.dart';
import 'package:app_piscina_v3/models/course.dart';
import 'package:app_piscina_v3/services/course_service.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:app_piscina_v3/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditCourse extends StatefulWidget {
  final String courseId;
  const EditCourse({super.key, required this.courseId});

  @override
  State<EditCourse> createState() => _EditCourseState();
}

class _EditCourseState extends State<EditCourse> {
  final _courseService = CourseService();
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  bool _isLoading = false;

  Course? _course;

  @override
  void initState() {
    _getCourseData();
    super.initState();
  }

  void _getCourseData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final course = await _courseService.getCourseById(widget.courseId);

      if (course != null) {
        setState(() {
          _course = course;
          _selectedDate = course.date;
          _selectedTime = TimeOfDay.fromDateTime(course.date);
          _timeController.text = DateFormat('HH:mm').format(_course!.date);
          _dateController.text = DateFormat('dd/MM/yyyy').format(_course!.date);
        });
      } else {
        setState(() {
          _course = null;
        });
      }
    } catch (e) {
      setState(() {
        _course = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _course!.date,
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
      initialTime: TimeOfDay.fromDateTime(_course!.date),
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

  void _editCourse() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final DateTime finalDatetime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final outcome = await _courseService.editCourse(
        widget.courseId,
        finalDatetime,
      );

      if (outcome && mounted) {
        Navigator.pop(context);
        showSuccessDialog(
          context,
          'Corso modificato correttamente, gli iscritti verranno notificati',
          onContinue: () => Nav.replace(context, const AdminLayout()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showErrorDialog(
          context,
          'Errore durante la modifica del corso',
          'Indietro',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Modifica corso')),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
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
                            onPressed: _isLoading ? null : _editCourse,
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
