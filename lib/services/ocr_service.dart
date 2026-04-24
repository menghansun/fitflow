import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'huawei_swim_ocr.dart';
import 'swim_screen_ocr.dart';
import 'swim_ocr_types.dart';

export 'swim_ocr_types.dart';

class HuaweiHealthOcrService {
  final _picker = ImagePicker();

  static OcrSourceBrand detectBrand(String text) {
    return OcrSourceBrand.huawei;
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
    return blocks != null
        ? HuaweiSwimOcrParser.parseWithBlocks(blocks, text)
        : HuaweiSwimOcrParser.parse(text);
  }
}
