import 'package:app_piscina_v3/models/child.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChildService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addChild(String parentId, Child child) async {
    try {
      await _db
          .collection('users')
          .doc(parentId)
          .collection('children')
          .add(child.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Child>> getChildren(String parentId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(parentId)
          .collection('children')
          .get();

      return snapshot.docs
          .map((doc) => Child.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
