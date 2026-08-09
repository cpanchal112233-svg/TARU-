import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Minimal Storage byte operations used by [ReportsRepository].
///
/// Production uses Firebase; tests use an in-memory implementation.
abstract class ReportObjectStore {
  Future<void> putData(
    String path,
    Uint8List bytes, {
    required String contentType,
    Map<String, String>? customMetadata,
    void Function(double progress)? onProgress,
  });

  Future<Uint8List> readAll(String path);

  Future<void> writeToFile(String path, String localPath);

  Future<String> downloadUrl(String path);

  /// Deletes [path]. Missing objects are treated as already clean.
  Future<void> deleteIfExists(String path);
}

class FirebaseReportObjectStore implements ReportObjectStore {
  FirebaseReportObjectStore(this._storage);

  final FirebaseStorage _storage;

  Reference _ref(String path) => _storage.ref(path);

  @override
  Future<void> putData(
    String path,
    Uint8List bytes, {
    required String contentType,
    Map<String, String>? customMetadata,
    void Function(double progress)? onProgress,
  }) async {
    final UploadTask task = _ref(path).putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: customMetadata,
      ),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        final int total = snapshot.totalBytes;
        if (total <= 0) return;
        onProgress(snapshot.bytesTransferred / total);
      });
    }

    await task;
  }

  @override
  Future<Uint8List> readAll(String path) async {
    final Uint8List? data = await _ref(path).getData(20 * 1024 * 1024);
    return data ?? Uint8List(0);
  }

  @override
  Future<void> writeToFile(String path, String localPath) {
    return _ref(path).writeToFile(File(localPath));
  }

  @override
  Future<String> downloadUrl(String path) => _ref(path).getDownloadURL();

  @override
  Future<void> deleteIfExists(String path) async {
    try {
      await _ref(path).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }
}
