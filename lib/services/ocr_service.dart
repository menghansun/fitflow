import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'generic_swim_ocr.dart';
import 'huawei_swim_ocr.dart';
import 'swim_screen_ocr.dart';
import 'swim_ocr_types.dart';
import 'xiaomi_swim_ocr.dart';

export 'swim_ocr_types.dart';

// ─────────────────────────────────────────────────────────
//  OCR 主服务（图片选择 + 品牌路由）
// ─────────────────────────────────────────────────────────
class HuaweiHealthOcrService {
  final _picker = ImagePicker();

  static OcrSourceBrand detectBrand(String text) {
    final hasHuawei = RegExp(r'华为|HUAWEI').hasMatch(text);
    final hasXiaomi = RegExp(r'小米|MIUI').hasMatch(text);
    if (hasXiaomi && !hasHuawei) return OcrSourceBrand.xiaomi;
    if (hasHuawei && !hasXiaomi) return OcrSourceBrand.huawei;
    final isHuawei = RegExp(r'划水次数|次/分钟').hasMatch(text);
    final isXiaomi = RegExp(r'平均划频|最佳配速|划程').hasMatch(text);
    if (isXiaomi && !isHuawei) return OcrSourceBrand.xiaomi;
    if (isHuawei && !isXiaomi) return OcrSourceBrand.huawei;
    return OcrSourceBrand.unknown;
  }

  Future<List<OcrPickResult>> pickAndParseImages() async {
    final List<XFile> files = await _picker.pickMultiImage(imageQuality: 95);
    if (files.isEmpty) return [];

    final List<OcrPickResult> results = [];
    for (final file in files) {
      final recognized = await recognizeSwimScreenshot(file.path);
      results.add(OcrPickResult(
        swimResult: parseSwimData(recognized.text, blocks: recognized.blocks),
      ));
    }

    return results;
  }

  SwimOcrResult parseSwimData(String text, {List<TextBlock>? blocks}) {
    final brand = detectBrand(text);
    switch (brand) {
      case OcrSourceBrand.huawei:
        return blocks != null
            ? HuaweiSwimOcrParser.parseWithBlocks(blocks, text)
            : HuaweiSwimOcrParser.parse(text);
      case OcrSourceBrand.xiaomi:
        return blocks != null
            ? XiaomiSwimOcrParser.parseWithBlocks(blocks, text)
            : XiaomiSwimOcrParser.parse(text);
      case OcrSourceBrand.unknown:
        return GenericSwimOcrParser.parse(text);
    }
  }
}
