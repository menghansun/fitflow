import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// Default horizontal strips (3 balances speed vs chart noise; use 4 for harder screenshots).
const int kDefaultSplitStrips = 3;

/// Overlap between adjacent strips as a fraction of [strip height] (reduces cut-through digits).
const double kDefaultOverlapFraction = 0.12;

/// Extra OCR pass on the top region (costs ~1 extra ML Kit run; off by default for speed).
const double kDefaultHeaderFraction = 0.27;

/// Below this width we upscale strips; 1080p phone screenshots skip resize (faster).
const int kMinStripWidthPx = 1080;

/// Avoid huge bitmaps on very wide sources.
const int kMaxStripWidthPx = 1680;

/// JPEG quality for temp strip files (lower = faster encode + smaller native decode).
const int kStripJpegQuality = 82;

/// Full-frame swim OCR: JPEG to ML Kit (higher = sharper text, slightly slower IO).
const int kSwimFullFrameJpegQuality = 90;

/// Full-frame swim OCR: contrast after preprocess (wide screenshots use [wideFlatContrast]).
const double kSwimFullFrameContrast = 1.08;

/// One ML Kit pass on the whole image (Chinese recognizer must be created by caller).
/// Set [preprocess] false to feed the file path directly (fastest, no temp JPEG).
Future<RecognizedText> recognizeFullImageMlKit(
  TextRecognizer recognizer,
  String imagePath, {
  bool preprocess = true,
  int jpegQuality = kSwimFullFrameJpegQuality,
  double contrast = kSwimFullFrameContrast,
  double headerBoost = 1.0,
}) async {
  if (!preprocess) {
    return recognizer.processImage(InputImage.fromFilePath(imagePath));
  }
  final bytes = await File(imagePath).readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) {
    return recognizer.processImage(InputImage.fromFilePath(imagePath));
  }
  final processed = _preprocessForMlKit(
    image,
    headerBoost: headerBoost,
    outputContrast: contrast,
    wideFlatContrast: contrast,
  );
  final jpg = img.encodeJpg(processed, quality: jpegQuality);
  final tmp = File(
    '${Directory.systemTemp.path}/fitflow_ocr_full_${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await tmp.writeAsBytes(jpg);
  try {
    return await recognizer.processImage(InputImage.fromFilePath(tmp.path));
  } finally {
    try {
      await tmp.delete();
    } catch (_) {}
  }
}

/// Runs ML Kit on optional [header] strip + overlapping horizontal strips (top → bottom),
/// deduplicates blocks in overlap zones, then merges [TextBlock.boundingBox] into full-image
/// coordinates for positional parsers.
Future<RecognizedText> recognizeWithHorizontalSplits(
  TextRecognizer recognizer,
  String imagePath, {
  int splits = kDefaultSplitStrips,
  double overlapFraction = kDefaultOverlapFraction,
  bool headerPass = false,
  double headerFraction = kDefaultHeaderFraction,
  bool preprocessStrips = true,
}) async {
  final bytes = await File(imagePath).readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) {
    return recognizer.processImage(InputImage.fromFilePath(imagePath));
  }

  final w = image.width;
  final h = image.height;
  if (h < splits * 8 || w < 8) {
    return recognizer.processImage(InputImage.fromFilePath(imagePath));
  }

  final allBlocks = <TextBlock>[];

  if (headerPass && headerFraction > 0 && headerFraction < 0.55) {
    final headerH = math.max(48, (h * headerFraction).floor());
    final headerCrop = img.copyCrop(image, x: 0, y: 0, width: w, height: headerH);
    final headerProcessed = _preprocessForMlKit(headerCrop, headerBoost: 1.22);
    final headerBlocks = await _runRecognizerOnBitmap(
      recognizer,
      headerProcessed,
      yOffset: 0,
    );
    allBlocks.addAll(headerBlocks);
  }

  final segmentLen = h / splits;
  final maxOverlap = (segmentLen * 0.45).floor();
  final overlapPx = math.min(
    maxOverlap,
    math.max(0, (segmentLen * overlapFraction).floor()),
  );
  final step = segmentLen - overlapPx;

  for (var i = 0; i < splits; i++) {
    final y0 = math.min(h - 1, math.max(0, (i * step).floor()));
    final y1 = i == splits - 1
        ? h
        : math.min(h, (y0 + segmentLen + overlapPx).round());
    final ch = y1 - y0;
    if (ch < 1) continue;

    final crop = img.copyCrop(image, x: 0, y: y0, width: w, height: ch);
    final processed =
        preprocessStrips ? _preprocessForMlKit(crop) : crop;
    final stripBlocks = await _runRecognizerOnBitmap(
      recognizer,
      processed,
      yOffset: y0.toDouble(),
    );
    allBlocks.addAll(stripBlocks);
  }

  final deduped = _dedupeTextBlocks(allBlocks);
  final mergedText = _textFromBlocksReadingOrder(deduped);

  if (mergedText.isEmpty && deduped.isEmpty) {
    return recognizer.processImage(InputImage.fromFilePath(imagePath));
  }

  return RecognizedText(text: mergedText, blocks: deduped);
}

/// Light upscale + contrast for small device screenshots (skip resize when already ~1080+ wide).
img.Image _preprocessForMlKit(
  img.Image src, {
  double headerBoost = 1.0,
  double outputContrast = 1.06,
  double wideFlatContrast = 1.05,
}) {
  var out = src;
  if (out.width >= kMinStripWidthPx && headerBoost <= 1.01) {
    return img.adjustColor(out, contrast: wideFlatContrast);
  }
  var targetW = out.width.toDouble();
  if (targetW < kMinStripWidthPx) {
    targetW = kMinStripWidthPx * headerBoost;
  } else {
    targetW *= headerBoost;
  }
  targetW = targetW.clamp(kMinStripWidthPx.toDouble(), kMaxStripWidthPx.toDouble());
  final scale = targetW / out.width;
  if ((scale - 1.0).abs() > 0.02) {
    final nh = math.max(1, (out.height * scale).round());
    final nw = math.max(1, (out.width * scale).round());
    out = img.copyResize(out, width: nw, height: nh, interpolation: img.Interpolation.linear);
  }
  out = img.adjustColor(out, contrast: outputContrast);
  return out;
}

Future<List<TextBlock>> _runRecognizerOnBitmap(
  TextRecognizer recognizer,
  img.Image bitmap,
  {required double yOffset}) async {
  final jpg = img.encodeJpg(bitmap, quality: kStripJpegQuality);
  final tmp = File(
    '${Directory.systemTemp.path}/fitflow_ocr_${DateTime.now().microsecondsSinceEpoch}_${yOffset.hashCode}.jpg',
  );
  await tmp.writeAsBytes(jpg);
  try {
    final input = InputImage.fromFilePath(tmp.path);
    final result = await recognizer.processImage(input);
    return result.blocks.map((b) => _offsetTextBlock(b, yOffset)).toList();
  } finally {
    try {
      await tmp.delete();
    } catch (_) {}
  }
}

TextBlock _offsetTextBlock(TextBlock b, double dy) {
  final r = b.boundingBox;
  final shiftedCorners = b.cornerPoints
      .map((p) => math.Point<int>(p.x, p.y + dy.toInt()))
      .toList();
  return TextBlock(
    text: b.text,
    lines: b.lines,
    boundingBox: Rect.fromLTRB(
      r.left,
      r.top + dy,
      r.right,
      r.bottom + dy,
    ),
    recognizedLanguages: b.recognizedLanguages,
    cornerPoints: shiftedCorners,
  );
}

double _rectIoU(Rect a, Rect b) {
  final left = math.max(a.left, b.left);
  final top = math.max(a.top, b.top);
  final right = math.min(a.right, b.right);
  final bottom = math.min(a.bottom, b.bottom);
  final iw = right - left;
  final ih = bottom - top;
  if (iw <= 0 || ih <= 0) return 0;
  final inter = iw * ih;
  final ua = a.width * a.height + b.width * b.height - inter;
  if (ua <= 0) return 0;
  return inter / ua;
}

bool _textNearDuplicate(String a, String b) {
  final ta = a.trim();
  final tb = b.trim();
  if (ta == tb) return true;
  if (ta.isEmpty || tb.isEmpty) return false;
  if (ta.contains(tb) || tb.contains(ta)) return true;
  return false;
}

/// Drop overlapping strip/header duplicates; prefer larger [boundingBox] area.
List<TextBlock> _dedupeTextBlocks(List<TextBlock> blocks) {
  if (blocks.length <= 1) return blocks;
  final sorted = blocks.toList()
    ..sort((a, b) {
      final aa = a.boundingBox.width * a.boundingBox.height;
      final ab = b.boundingBox.width * b.boundingBox.height;
      return ab.compareTo(aa);
    });
  final kept = <TextBlock>[];
  for (final candidate in sorted) {
    var duplicate = false;
    for (final k in kept) {
      final iou = _rectIoU(candidate.boundingBox, k.boundingBox);
      if (iou >= 0.38 && _textNearDuplicate(candidate.text, k.text)) {
        duplicate = true;
        break;
      }
    }
    if (!duplicate) kept.add(candidate);
  }
  return kept;
}

String _textFromBlocksReadingOrder(List<TextBlock> blocks) {
  if (blocks.isEmpty) return '';
  final sorted = blocks.toList()
    ..sort((a, b) {
      final ta = a.boundingBox.top;
      final tb = b.boundingBox.top;
      if ((ta - tb).abs() > 6) return ta.compareTo(tb);
      return a.boundingBox.left.compareTo(b.boundingBox.left);
    });
  return sorted.map((b) => b.text).join('\n');
}

/// Public helper: merge ML Kit-style blocks top-to-then-left for parsers that also read [rawText].
String mergeMlKitBlocksToPlainText(List<TextBlock> blocks) =>
    _textFromBlocksReadingOrder(blocks);
