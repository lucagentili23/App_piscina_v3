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
}
