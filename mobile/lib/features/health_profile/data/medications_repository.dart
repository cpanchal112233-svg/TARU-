import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/medication.dart';

class MedicationsRepository {
  MedicationsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _medicationsDocument(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('health')
          .doc('medications');

  Stream<MedicationRecord> watch(String uid) {
    return _medicationsDocument(uid).snapshots().map((snapshot) {
      final Map<String, dynamic>? data = snapshot.data();

      if (!snapshot.exists || data == null) return MedicationRecord.empty;

      return MedicationRecord.fromMap(data);
    });
  }

  Future<void> save(String uid, MedicationRecord record) {
    return _medicationsDocument(uid).set(<String, dynamic>{
      'items': record.medications
          .map((UserMedication medication) => medication.toMap())
          .toList(),
      'takesNoMedication': record.takesNoMedication,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
