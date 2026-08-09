import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:mobile/features/reports/data/report_object_store.dart';

/// In-memory [ReportObjectStore] for repository tests.
class MemoryReportObjectStore implements ReportObjectStore {
  final Map<String, Uint8List> objects = <String, Uint8List>{};
  final Map<String, String> contentTypes = <String, String>{};

  bool failNextPut = false;
  int failNextPutAfterSuccessCount = -1;
  int putCount = 0;
  bool failDelete = false;
  final Set<String> failDeletePaths = <String>{};

  @override
  Future<void> putData(
    String path,
    Uint8List bytes, {
    required String contentType,
    Map<String, String>? customMetadata,
    void Function(double progress)? onProgress,
  }) async {
    putCount += 1;
    if (failNextPut) {
      failNextPut = false;
      throw FirebaseException(plugin: 'storage', code: 'unknown', message: 'put');
    }
    if (failNextPutAfterSuccessCount >= 0 &&
        putCount > failNextPutAfterSuccessCount) {
      throw FirebaseException(plugin: 'storage', code: 'unknown', message: 'put');
    }
    objects[path] = Uint8List.fromList(bytes);
    contentTypes[path] = contentType;
    onProgress?.call(1);
  }

  @override
  Future<Uint8List> readAll(String path) async {
    final Uint8List? bytes = objects[path];
    if (bytes == null) {
      throw FirebaseException(
        plugin: 'storage',
        code: 'object-not-found',
        message: path,
      );
    }
    return Uint8List.fromList(bytes);
  }

  @override
  Future<void> writeToFile(String path, String localPath) async {
    final Uint8List bytes = await readAll(path);
    await File(localPath).writeAsBytes(bytes, flush: true);
  }

  @override
  Future<String> downloadUrl(String path) async {
    if (!objects.containsKey(path)) {
      throw FirebaseException(
        plugin: 'storage',
        code: 'object-not-found',
        message: path,
      );
    }
    return 'memory://$path';
  }

  @override
  Future<void> deleteIfExists(String path) async {
    if (failDelete || failDeletePaths.contains(path)) {
      throw FirebaseException(
        plugin: 'storage',
        code: 'unknown',
        message: 'delete',
      );
    }
    objects.remove(path);
    contentTypes.remove(path);
  }
}
