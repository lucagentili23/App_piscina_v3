import 'package:app_piscina_v3/models/child.dart';
import 'package:app_piscina_v3/models/course.dart';
import 'package:app_piscina_v3/models/user_model.dart';
import 'package:app_piscina_v3/screens/add_child.dart';
import 'package:app_piscina_v3/screens/course_details_user.dart';
import 'package:app_piscina_v3/screens/edit_child.dart';
import 'package:app_piscina_v3/services/user_service.dart';
import 'package:app_piscina_v3/services/child_service.dart';
import 'package:app_piscina_v3/services/course_service.dart';
import 'package:app_piscina_v3/theme.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:app_piscina_v3/utils/general_utils.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:flutter/material.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<StatefulWidget> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final _authService = UserService();
  final _childService = ChildService();
  final _courseService = CourseService();

  UserModel? _user;
  List<Child> _children = [];
  List<Map<String, dynamic>> _bookedData = [];

  bool _isLoading = true;

  @override
  void initState() {
    _loadData();
    _authService.saveDeviceToken();
    super.initState();
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    try {
      if (!isRefresh) {
        setState(() {
          _isLoading = true;
        });
      }
      final user = await _authService.getUserData();
      List<Child> children = [];
      List<Map<String, dynamic>> bookedData = [];

      if (user != null) {
        children = await _childService.getChildren(user.id);
        bookedData = await _courseService.getBookedCourses(user.id);
      }

      setState(() {
        _user = user;
        _children = children;
        _bookedData = bookedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteChild(String childId) async {
    try {
      final confirm = await showConfirmDialog(
        context,
        'Sei sicuro di voler rimuovere il figlio selezionato?\nVerrà rimosso da tutti i corsi a cui è iscritto',
      );

      if (!confirm) return;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final outcome = await _childService.deleteChild(
        _authService.currentUser!.uid,
        childId,
      );

      if (outcome && mounted) {
        Navigator.pop(context);

        showSuccessDialog(
          context,
          'Figlio rimosso con successo',
          onContinue: () => setState(() {
            _loadData();
          }),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Errore durante la rimozione del figlio',
          'Continua',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text("Errore durante il caricamento dei dati."),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text("Riprova")),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: () => _loadData(isRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage(_user!.photoUrl),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bentornato,',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _user!.firstName,
                                style: TextStyle(
                                  fontSize: 28,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Le tue prenotazioni",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_bookedData.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(
                            child: Text(
                              "Nessuna prenotazione attiva",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._bookedData.map((data) {
                          final course = data['course'] as Course;
                          final names = data['names'] as List<String>;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.lightSecondaryColor,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child:
                                            course.type == CourseType.idrobike
                                            ? Icon(Icons.pedal_bike_outlined)
                                            : Icon(Icons.pool),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              course.type.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              dateAndTimeToString(course.date),
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Nav.to(
                                          context,
                                          CourseDetailsUser(
                                            courseId: course.id,
                                          ),
                                        ),
                                        child: Text('Visualizza'),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Partecipanti: ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          names.join(", "),
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const Divider(),
                      _children.isEmpty
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Hai dei figli da iscrivere?'),
                                TextButton(
                                  onPressed: () =>
                                      Nav.to(context, const AddChild()),
                                  child: Text('Clicca qui'),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "I tuoi figli registrati:",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ..._children.map(
                                  (child) => _buildChildHeader(child),
                                ),
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        Nav.to(context, const AddChild()),
                                    icon: const Icon(Icons.add),
                                    label: const Text("Aggiungi"),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChildHeader(Child child) {
    return Card(
      elevation: 4,

      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage(child.photoUrl),
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "${child.firstName} ${child.lastName}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            IconButton(
              onPressed: () => Nav.to(context, EditChild(childId: child.id)),
              icon: Icon(Icons.edit),
              color: Colors.grey[700],
            ),
            IconButton(
              onPressed: () => _deleteChild(child.id),
              icon: Icon(Icons.delete),
              color: Colors.grey[700],
            ),
          ],
        ),
      ),
    );
  }
}
