import 'package:app_piscina_v3/models/user_model.dart';
import 'package:app_piscina_v3/utils/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get user {
    return _firebaseAuth.authStateChanges();
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String lastName,
    required Gender gender,
    required UserRole role,
  }) async {
    try {
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
      'children': [],
      'role': role.name,
      'createdAt': FieldValue.serverTimestamp(),
      'photoUrl': gender == Gender.m
          ? 'assets/images/Immagine_profilo_m.png'
          : 'assets/images/Immagine_profilo_f.png',
    });
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
}
