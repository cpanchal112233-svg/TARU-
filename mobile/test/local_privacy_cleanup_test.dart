import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/privacy/data/local_privacy_cleanup.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.temporaryPath);

  final String temporaryPath;

  @override
  Future<String?> getTemporaryPath() async => temporaryPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late LocalPrivacyCleanup cleanup;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('privacy_cleanup_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempRoot.path);
    cleanup = LocalPrivacyCleanup();
  });

  tearDown(() async {
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('clearTaruTempFiles removes taru_ocr_* directories recursively', () async {
    final Directory ocrDir = Directory(p.join(tempRoot.path, 'taru_ocr_r42'));
    await ocrDir.create(recursive: true);
    await File(p.join(ocrDir.path, 'norm_r42.png')).writeAsString('png');
    await File(p.join(ocrDir.path, 'nested', 'page.txt'))
        .create(recursive: true)
        .then((File f) => f.writeAsString('page'));

    await cleanup.clearTaruTempFiles();

    expect(ocrDir.existsSync(), isFalse);
  });

  test('clearTaruTempFiles leaves unrelated temp files', () async {
    final Directory ocrDir = Directory(p.join(tempRoot.path, 'taru_ocr_r99'));
    await ocrDir.create(recursive: true);
    await File(p.join(ocrDir.path, 'scratch.txt')).writeAsString('x');

    final File unrelated = File(p.join(tempRoot.path, 'other_app_cache.tmp'));
    await unrelated.writeAsString('keep');

    await cleanup.clearTaruTempFiles();

    expect(ocrDir.existsSync(), isFalse);
    expect(unrelated.existsSync(), isTrue);
  });

  test('clearTaruTempFiles removes taru_export_* files and dirs', () async {
    final Directory exportDir =
        Directory(p.join(tempRoot.path, 'taru_export_user_20260809'));
    await exportDir.create(recursive: true);
    await File(p.join(exportDir.path, 'manifest.json')).writeAsString('{}');
    final File exportZip =
        File(p.join(tempRoot.path, 'taru_export_user_20260809.zip'));
    await exportZip.writeAsString('zip');

    await cleanup.clearTaruTempFiles();

    expect(exportDir.existsSync(), isFalse);
    expect(exportZip.existsSync(), isFalse);
  });
}
