// Unknown-brand fallback: merge Huawei + Xiaomi text parsers field-by-field.

import 'huawei_swim_ocr.dart';
import 'swim_ocr_types.dart';
import 'xiaomi_swim_ocr.dart';

class GenericSwimOcrParser {
  GenericSwimOcrParser._();

  /// No block positions — runs both brand parsers on full text and merges.
  static SwimOcrResult parse(String text) {
    final h = HuaweiSwimOcrParser.parse(text);
    final x = XiaomiSwimOcrParser.parse(text);

    return SwimOcrResult(
      sourceBrand: OcrSourceBrand.unknown,
      distanceMeters: h.distanceMeters ?? x.distanceMeters,
      durationMinutes: h.durationMinutes ?? x.durationMinutes,
      durationRaw: h.durationRaw ?? x.durationRaw,
      calories: h.calories ?? x.calories,
      avgHeartRate: h.avgHeartRate,
      maxHeartRate: h.maxHeartRate,
      swimStyle: h.swimStyle ?? x.swimStyle,
      laps: h.laps ?? x.laps,
      poolLength: h.poolLength ?? x.poolLength,
      avgPace: h.avgPace ?? x.avgPace,
      bestPace: h.bestPace ?? x.bestPace,
      swolfAvg: h.swolfAvg ?? x.swolfAvg,
      swolfBest: h.swolfBest ?? x.swolfBest,
      strokeRate: h.strokeRate ?? x.strokeRate,
      strokeCount: h.strokeCount ?? x.strokeCount,
      workoutDateTime: h.workoutDateTime ?? x.workoutDateTime,
    );
  }
}
