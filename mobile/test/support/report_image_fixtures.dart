import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as im;
import 'package:path/path.dart' as p;

/// Synthetic raster fixtures for OCR/normalizer tests (no real PHI).
class ReportImageFixtures {
  static const String root = 'test/fixtures/reports';

  static Future<void> ensureOnDisk() async {
    final Directory dir = Directory(root);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    await _writeIfMissing('upright.jpg', _uprightJpeg());
    await _writeAlways('exif_oriented.jpg', _exifOrientedJpeg());
    await _writeIfMissing('sample.png', _samplePng());
    await _writeIfMissing('sample.webp', _sampleWebp());
    await _writeIfMissing('blank.png', _blankPng());
  }

  static File file(String name) {
    final File f = File(p.join(root, name));
    if (!f.existsSync()) {
      throw StateError('Missing fixture ${f.path}; call ensureOnDisk() first.');
    }
    return f;
  }

  static Future<void> _writeIfMissing(String name, Uint8List bytes) async {
    final File out = File(p.join(root, name));
    if (!out.existsSync()) {
      await out.writeAsBytes(bytes, flush: true);
    }
  }

  static Future<void> _writeAlways(String name, Uint8List bytes) async {
    final File out = File(p.join(root, name));
    await out.writeAsBytes(bytes, flush: true);
  }

  /// High-contrast asymmetric pattern (red bar on the left).
  static im.Image _labeledPattern({required int width, required int height}) {
    final im.Image image = im.Image(width: width, height: height);
    im.fill(image, color: im.ColorRgb8(255, 255, 255));
    im.fillRect(
      image,
      x1: 0,
      y1: 0,
      x2: width ~/ 4,
      y2: height,
      color: im.ColorRgb8(200, 0, 0),
    );
    im.drawString(
      image,
      'TARU-FIXTURE',
      font: im.arial14,
      x: width ~/ 4 + 4,
      y: height ~/ 2 - 7,
      color: im.ColorRgb8(0, 0, 0),
    );
    return image;
  }

  static Uint8List _uprightJpeg() {
    return Uint8List.fromList(
      im.encodeJpg(_labeledPattern(width: 240, height: 120), quality: 90),
    );
  }

  /// Pixel data is landscape; EXIF orientation 6 requests 90° CW bake.
  static Uint8List _exifOrientedJpeg() {
    final im.Image image = _labeledPattern(width: 240, height: 120);
    image.exif.imageIfd.orientation = 6;
    return Uint8List.fromList(im.encodeJpg(image, quality: 90));
  }

  static Uint8List _samplePng() {
    return Uint8List.fromList(
      im.encodePng(_labeledPattern(width: 160, height: 80)),
    );
  }

  static Uint8List _sampleWebp() {
    // package:image decodes WebP but does not encode it in this release;
    // PNG bytes are sniffed correctly regardless of .webp extension.
    return _samplePng();
  }

  static Uint8List _blankPng() {
    final im.Image blank = im.Image(width: 64, height: 64);
    im.fill(blank, color: im.ColorRgb8(255, 255, 255));
    return Uint8List.fromList(im.encodePng(blank));
  }
}
