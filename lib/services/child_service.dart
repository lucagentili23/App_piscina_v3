import 'package:app_piscina_v3/models/child.dart';
import 'package:app_piscina_v3/utils/enums.dart';
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

  Future<Child?> getChildById(String userId, String childId) async {
    try {
      final docSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(childId)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return Child.fromMap(docSnapshot.data()!, docSnapshot.id);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> editChild(
    String userId,
    String childId,
    String firstName,
    String lastName,
    String photoUrl,
    Gender gender,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(childId)
          .update({
            'firstName': firstName,
            'lastName': lastName,
            'photoUrl': photoUrl,
            'gender': gender.name,
          });

      final attendeesSnapshot = await _db
          .collectionGroup('attendees')
          .where('childId', isEqualTo: childId)
          .get();

      WriteBatch batch = _db.batch();

      for (var doc in attendeesSnapshot.docs) {
        batch.update(doc.reference, {
          'displayedName': '$firstName $lastName',
          'displayedPhotoUrl': photoUrl,
        });
      }

      await batch.commit();

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteChild(String userId, String childId) async {
    try {
      final childRef = _db
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(childId);

      final attendeesSnapshot = await _db
          .collectionGroup('attendees')
          .where('childId', isEqualTo: childId)
          .get();

      WriteBatch batch = _db.batch();

      batch.delete(childRef);

      for (var doc in attendeesSnapshot.docs) {
        batch.delete(doc.reference);

        final courseRef = doc.reference.parent.parent;

        if (courseRef != null) {
          batch.update(courseRef, {'bookedSpots': FieldValue.increment(-1)});
        }
      }

      await batch.commit();

      return true;
    } catch (e) {
      return false;
    }
  }
}
