import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'mlkit_split_screen_ocr.dart';

/// Swim import: single ML Kit Chinese pass on the full image (preprocess knobs in
/// [recognizeFullImageMlKit]: [kSwimFullFrameJpegQuality], [kSwimFullFrameContrast]).
Future<RecognizedText> recognizeSwimScreenshot(String imagePath) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.chinese);
  try {
    return await recognizeFullImageMlKit(recognizer, imagePath);
  } finally {
    await recognizer.close();
  }
}
