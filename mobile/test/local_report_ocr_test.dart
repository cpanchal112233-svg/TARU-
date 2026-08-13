import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as im;
import 'package:mobile/features/reports/data/local_report_ocr.dart';
import 'package:mobile/features/reports/data/report_image_normalizer.dart';
import 'package:mobile/features/reports/domain/report_extraction.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'support/report_image_fixtures.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.temporaryPath);

  final String temporaryPath;

  @override
  Future<String?> getTemporaryPath() async => temporaryPath;
}

class _MarkerNormalizer extends ReportImageNormalizer {
  @override
  Future<File> normalizeToPngFile({
    required File source,
    required Directory workDir,
    required String reportId,
  }) async {
    await workDir.create(recursive: true);
    await File(p.join(workDir.path, 'marker.txt')).writeAsString('temp');
    throw StateError('normalizer failed');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late ReportImageNormalizer normalizer;

  setUpAll(() async {
    await ReportImageFixtures.ensureOnDisk();
  });

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ocr_unit_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempRoot.path);
    normalizer = ReportImageNormalizer();
  });

  tearDown(() async {
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('LocalReportOcr.combinePageTexts', () {
    test('joins non-blank pages with blank line separator', () {
      expect(
        LocalReportOcr.combinePageTexts(<String>['Page A', 'Page B']),
        'Page A\n\nPage B',
      );
    });

    test('skips blank pages', () {
      expect(
        LocalReportOcr.combinePageTexts(<String>['Only', '   ', '\n', 'Last']),
        'Only\n\nLast',
      );
    });

    test('returns empty when all pages blank', () {
      expect(LocalReportOcr.combinePageTexts(<String>['', '  ']), '');
    });
  });

  group('ReportImageNormalizer', () {
    Future<File> normalizeFixture(String fixtureName) async {
      final Directory work = Directory(p.join(tempRoot.path, 'norm_work'));
      await work.create(recursive: true);
      return normalizer.normalizeToPngFile(
        source: ReportImageFixtures.file(fixtureName),
        workDir: work,
        reportId: 'fix1',
      );
    }

    test('decodes upright JPEG to PNG', () async {
      final File png = await normalizeFixture('upright.jpg');
      expect(p.extension(png.path), '.png');
      final im.Image? decoded = im.decodePng(await png.readAsBytes());
      expect(decoded, isNotNull);
      expect(decoded!.width, greaterThan(0));
      expect(decoded.height, greaterThan(0));
    });

    test('decodes PNG fixture', () async {
      final File png = await normalizeFixture('sample.png');
      expect(await png.length(), greaterThan(0));
      expect(im.decodePng(await png.readAsBytes()), isNotNull);
    });

    test('decodes WebP fixture', () async {
      final File png = await normalizeFixture('sample.webp');
      expect(im.decodePng(await png.readAsBytes()), isNotNull);
    });

    test('exif-oriented JPEG carries orientation metadata', () {
      final im.ExifData? exif = im.decodeJpgExif(
        ReportImageFixtures.file('exif_oriented.jpg').readAsBytesSync(),
      );
      expect(exif?.imageIfd.orientation, 6);
    });

    test('normalizer decodes exif-oriented JPEG to PNG', () async {
      final File png = await normalizeFixture('exif_oriented.jpg');
      expect(im.decodePng(await png.readAsBytes()), isNotNull);
    });

    test('decodes blank PNG without error', () async {
      final File png = await normalizeFixture('blank.png');
      final im.Image? decoded = im.decodePng(await png.readAsBytes());
      expect(decoded, isNotNull);
      expect(decoded!.width, 64);
      expect(decoded.height, 64);
    });
  });

  group('LocalReportOcr temp cleanup', () {
    test('deletes taru_ocr work dir when normalizer fails', () async {
      final LocalReportOcr ocr = LocalReportOcr(normalizer: _MarkerNormalizer());
      final File source = ReportImageFixtures.file('upright.jpg');
      final Directory workDir = Directory(p.join(tempRoot.path, 'taru_ocr_r1'));

      await expectLater(
        ocr.recognizeImageFile(source: source, reportId: 'r1'),
        throwsA(isA<ReportOcrException>()),
      );

      expect(workDir.existsSync(), isFalse);
    });
  });

  group('device OCR (ML Kit)', () {
    test(
      'recognizeImageFile reads text from synthetic JPEG',
      () async {
        final LocalReportOcr ocr = LocalReportOcr(normalizer: normalizer);
        final File source = ReportImageFixtures.file('upright.jpg');

        final String text = await ocr.recognizeImageFile(
          source: source,
          reportId: 'device1',
        );

        expect(text.trim(), isNotEmpty);
        expect(
          Directory(p.join(tempRoot.path, 'taru_ocr_device1')).existsSync(),
          isFalse,
        );
      },
      skip: _mlKitUnavailableReason(),
    );
  });
}

String? _mlKitUnavailableReason() {
  if (Platform.isMacOS && !Platform.environment.containsKey('FLUTTER_TEST_DEVICE')) {
    return 'ML Kit text recognition requires iOS/Android device or emulator.';
  }
  return null;
}
