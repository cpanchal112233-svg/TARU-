import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as im;
import 'package:path/path.dart' as p;

/// Deterministic upright normalization before OCR.
///
/// JPEG/PNG/WebP: [package:image] decode + EXIF bake.
/// HEIC/HEIF: Flutter platform codec ([ui.instantiateImageCodec]) — not
/// package:image (which cannot decode HEIC).
///
/// Does not guess orientation via OCR. Physically sideways files without
/// usable metadata remain as-is; UI may suggest rotating the report.
class ReportImageNormalizer {
  /// Writes an upright PNG under [workDir] and returns that file.
  Future<File> normalizeToPngFile({
    required File source,
    required Directory workDir,
    required String reportId,
  }) async {
    final Uint8List bytes = await source.readAsBytes();
    final String lower = source.path.toLowerCase();
    final bool heic =
        lower.endsWith('.heic') || lower.endsWith('.heif') || _looksHeic(bytes);

    final Uint8List pngBytes = heic
        ? await _heicToPng(bytes)
        : _rasterToPng(bytes);

    await workDir.create(recursive: true);
    final File out = File(
      p.join(workDir.path, 'norm_${reportId}_${_safeBase(source)}.png'),
    );
    await out.writeAsBytes(pngBytes, flush: true);
    return out;
  }

  Uint8List _rasterToPng(Uint8List bytes) {
    final im.Image? decoded = im.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Could not decode image for OCR.');
    }
    final im.Image oriented = im.bakeOrientation(decoded);
    return Uint8List.fromList(im.encodePng(oriented));
  }

  Future<Uint8List> _heicToPng(Uint8List bytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;
    try {
      final ByteData? png = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (png == null) {
        throw StateError('Could not encode HEIC image for OCR.');
      }
      return png.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  bool _looksHeic(Uint8List b) {
    if (b.length < 12) return false;
    return b[4] == 0x66 &&
        b[5] == 0x74 &&
        b[6] == 0x79 &&
        b[7] == 0x70 &&
        ((b[8] == 0x68 && b[9] == 0x65 && b[10] == 0x69 && b[11] == 0x63) ||
            (b[8] == 0x6d && b[9] == 0x69 && b[10] == 0x66 && b[11] == 0x31));
  }

  String _safeBase(File source) {
    final String base = p.basenameWithoutExtension(source.path);
    return base.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }
}
