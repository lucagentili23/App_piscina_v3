import 'package:app_piscina_v3/models/course.dart';
import 'package:app_piscina_v3/models/user_model.dart';
import 'package:app_piscina_v3/screens/course_details_admin.dart';
import 'package:app_piscina_v3/services/course_service.dart';
import 'package:app_piscina_v3/services/user_service.dart';
import 'package:app_piscina_v3/theme.dart';
import 'package:app_piscina_v3/utils/dialogs.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:app_piscina_v3/utils/general_utils.dart';
import 'package:app_piscina_v3/utils/navigation.dart';
import 'package:flutter/material.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<StatefulWidget> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final _userService = UserService();
  final _courseService = CourseService();
  UserModel? _user;
  bool _isLoading = true;
  List<UserModel> _admins = [];
  List<Course> _dailyCourses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _userService.saveDeviceToken();
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    try {
      if (!isRefresh) {
        setState(() {
          _isLoading = true;
        });
      }

      final user = await _userService.getUserData();
      List<UserModel> admins = [];
      List<Course> dailyCourses = [];

      if (user != null) {
        final results = await Future.wait([
          _userService.getAdmins(user.id),
          _courseService.getDailyCourses(),
        ]);

        admins = results[0] as List<UserModel>;
        dailyCourses = results[1] as List<Course>;
      }

      setState(() {
        _user = user;
        _admins = admins;
        _dailyCourses = dailyCourses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _makeUser(String userId, String userName) async {
    try {
      final confirm = await showConfirmDialog(
        context,
        'Sei sicuro di voler rendere l\'utente $userName un utente base?',
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

      final outcome = await _userService.makeUser(userId);

      if (outcome && mounted) {
        Navigator.pop(context);
        showSuccessDialog(
          context,
          'Operazione eseguita correttamente',
          onContinue: () {
            setState(() {
              _isLoading = true;
            });
            _loadData();
          },
        );
      }

      if (!outcome && mounted) {
        Navigator.pop(context);
        showErrorDialog(
          context,
          'Errore durante l\'esecuzione dell\'operazione',
          'Indietro',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Errore durante l\'esecuzione dell\'operazione',
          'Indietro',
        );
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
                        crossAxisAlignment: CrossAxisAlignment
                            .center, // Meglio center per allineare con l'avatar
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage(_user!.photoUrl),
                          ),
                          const SizedBox(width: 20),
                          // Aggiungi Expanded qui
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ciao,',
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
                                  // Aggiungi queste proprietà per gestire il testo lungo
                                  overflow: TextOverflow
                                      .ellipsis, // Mette i puntini "..." se troppo lungo
                                  maxLines:
                                      2, // Oppure permetti di andare a capo su massimo 2 righe
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      Row(
                        children: [
                          const Icon(
                            Icons.assignment_turned_in,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Lista dei corsi di oggi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_dailyCourses.isEmpty)
                        Text(
                          'Non sono previsti corsi per oggi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      if (_dailyCourses.isNotEmpty)
                        ..._dailyCourses.map((course) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 3,
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
                                          color: AppTheme.lightPrimaryColor,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          course.type == CourseType.idrobike
                                              ? Icons.pedal_bike_outlined
                                              : Icons.pool,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              course.type.name.toUpperCase(),
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
                                          CourseDetailsAdmin(
                                            courseId: course.id,
                                          ),
                                        ),
                                        child: const Text('Visualizza'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      Divider(),
                      const SizedBox(height: 10),
                      _admins.isEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'Lista degli amministratori',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Non sono ancora presenti altri amministratori',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'Lista degli amministratori',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                ..._admins.map(
                                  (child) => _buildAdminHeader(child),
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

  Widget _buildAdminHeader(UserModel user) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage(user.photoUrl),
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "${user.firstName} ${user.lastName}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            TextButton(
              onPressed: () => _makeUser(user.id, user.fullName),
              child: Text('Rimuovi'),
            ),
          ],
        ),
      ),
    );
  }
}
