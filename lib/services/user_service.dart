import 'dart:io';
import 'package:app_piscina_v3/models/user_model.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class UserService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Stream<User?> get user => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String lastName,
    required Gender gender,
    required UserRole role,
    required String accessCode,
  }) async {
    try {
      String? code;

      final accessCodeDocRef = await _db
          .collection('settings')
          .doc('registration')
          .get();

      if (accessCodeDocRef.exists) {
        code = accessCodeDocRef.get('accessCode');
      }

      if (accessCode != code) {
        throw 'invalid-access-code';
      }

      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      if (user != null) {
        await _createFirestoreUser(
          user: user,
          email: email,
          name: name,
          lastName: lastName,
          gender: gender,
          role: role,
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'email-already-in-use';
      }
      throw e.code;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw 'user-not-found';
      } else if (e.code == 'too-many-requests') {
        throw 'too-many-requests';
      } else {
        throw 'unknown-error';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> _createFirestoreUser({
    required User user,
    required String email,
    required String name,
    required String lastName,
    required Gender gender,
    required UserRole role,
  }) async {
    final userRef = _db.collection('users').doc(user.uid);

    await userRef.set({
      'id': user.uid,
      'email': email,
      'firstName': name,
      'lastName': lastName,
      'gender': gender.name,
      'role': role.name,
      'isDisabled': false,
      'createdAt': FieldValue.serverTimestamp(),
      'photoUrl': gender == Gender.m
          ? 'assets/images/Immagine_profilo_m.png'
          : 'assets/images/Immagine_profilo_f.png',
    });
  }

  Future<void> saveDeviceToken() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) return;

      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        return;
      }

      // PER IOS: Attendi il token APNS prima di chiedere quello FCM
      if (Platform.isIOS) {
        String? apnsToken = await messaging.getAPNSToken();

        // Se è null, aspetta un attimo e riprova (spesso ci mette qualche secondo all'avvio)
        if (apnsToken == null) {
          await Future.delayed(const Duration(seconds: 3));
          apnsToken = await messaging.getAPNSToken();
        }

        if (apnsToken == null) {
          return;
        }
      }

      // Ora è sicuro chiedere il token FCM
      final token = await messaging.getToken();

      if (token != null) {
        await _db.collection('users').doc(currentUser.uid).set({
          'fcmToken': token,
          'platform': Platform.operatingSystem,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Ascolta cambiamenti del token nel tempo
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _db.collection('users').doc(currentUser.uid).set({
          'fcmToken': newToken,
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('Errore salvataggio token: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) return;

      await _db
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      debugPrint('Errore durante la lettura della notifica: $e');
    }
  }

  Stream<bool> get unreadNotificationsStream {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return Stream.value(false);
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  Future<UserRole?> getUserRole() async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser != null) {
        final doc = await _db.collection('users').doc(currentUser.uid).get();

        if (doc.exists) {
          final role = doc.get('role');

          if (role == 'admin') {
            return UserRole.admin;
          } else {
            return UserRole.user;
          }
        }
        return null;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<UserModel?> getUserData() async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser != null) {
        final doc = await _db.collection('users').doc(currentUser.uid).get();

        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!, currentUser.uid);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<UserModel>> getUsers() async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();

      final List<UserModel> users = querySnapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();

      return users;
    } catch (e) {
      return [];
    }
  }

  Future<void> toggleUserStatus(String uid) async {
    try {
      await _functions.httpsCallable('toggleUserStatus').call({'uid': uid});
    } on FirebaseFunctionsException catch (e) {
      throw e.message ?? 'Errore durante l\'aggiornamento dello stato utente.';
    } catch (e) {
      throw 'Errore sconosciuto: $e';
    }
  }

  Future<void> deleteUserAccount(String uid) async {
    try {
      await _functions.httpsCallable('deleteUserAccount').call({'uid': uid});
    } on FirebaseFunctionsException catch (e) {
      throw e.message ?? 'Errore durante l\'eliminazione dell\'utente.';
    } catch (e) {
      throw 'Errore sconosciuto: $e';
    }
  }

  Future<List<UserModel>> getAdmins(String adminId) async {
    try {
      List<UserModel> admins = [];

      final querySnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .where('id', isNotEqualTo: adminId)
          .get();

      for (var doc in querySnapshot.docs) {
        admins.add(UserModel.fromMap(doc.data(), doc.id));
      }

      return admins;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<bool> makeAdmin(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({'role': 'admin'});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> makeUser(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({'role': 'user'});
      return true;
    } catch (e) {
      return false;
    }
  }
}
