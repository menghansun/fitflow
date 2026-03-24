// Shared OCR result types for swim screenshots (brand-agnostic).

enum OcrSourceBrand {
  huawei,
  xiaomi,
  unknown,
}

extension OcrSourceBrandExt on OcrSourceBrand {
  String get displayName {
    switch (this) {
      case OcrSourceBrand.huawei:
        return '华为运动健康';
      case OcrSourceBrand.xiaomi:
        return '小米运动健康';
      case OcrSourceBrand.unknown:
        return '未知来源';
    }
  }
}

class SwimOcrResult {
  final OcrSourceBrand sourceBrand;
  final int? distanceMeters;
  final int? durationMinutes;
  final String? durationRaw;
  final int? calories;
  final int? avgHeartRate;
  final int? maxHeartRate;
  final String? swimStyle;
  final int? laps;
  final int? poolLength;
  final String? avgPace;
  final String? bestPace;
  final int? swolfAvg;
  final int? swolfBest;
  final int? strokeRate;
  final int? strokeCount;
  final DateTime? workoutDateTime;

  const SwimOcrResult({
    this.sourceBrand = OcrSourceBrand.unknown,
    this.distanceMeters,
    this.durationMinutes,
    this.durationRaw,
    this.calories,
    this.avgHeartRate,
    this.maxHeartRate,
    this.swimStyle,
    this.laps,
    this.poolLength,
    this.avgPace,
    this.bestPace,
    this.swolfAvg,
    this.swolfBest,
    this.strokeRate,
    this.strokeCount,
    this.workoutDateTime,
  });

  bool get isEmpty =>
      distanceMeters == null &&
      durationMinutes == null &&
      calories == null &&
      avgHeartRate == null &&
      maxHeartRate == null &&
      swimStyle == null &&
      laps == null &&
      poolLength == null &&
      avgPace == null &&
      bestPace == null &&
      swolfAvg == null &&
      swolfBest == null &&
      strokeRate == null &&
      strokeCount == null;
}

class OcrPickResult {
  final SwimOcrResult swimResult;

  const OcrPickResult({required this.swimResult});
}
