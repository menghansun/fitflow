import 'package:hive/hive.dart';

part 'body_metrics.g.dart';

@HiveType(typeId: 11)
class BodyMetrics extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late DateTime date;

  /// 体重 (kg)
  @HiveField(2)
  double? weight;

  /// 身高 (cm) - 用于计算 BMI
  @HiveField(3)
  double? height;

  /// 体脂率 (%)
  @HiveField(4)
  double? bodyFatPercentage;

  /// 肌肉含量 (kg)
  @HiveField(5)
  double? muscleMass;

  /// 基础代谢率 (kcal)
  @HiveField(6)
  int? basalMetabolicRate;

  /// 备注
  @HiveField(7)
  String? notes;

  BodyMetrics({
    required this.id,
    required this.date,
    this.weight,
    this.height,
    this.bodyFatPercentage,
    this.muscleMass,
    this.basalMetabolicRate,
    this.notes,
  });

  /// 计算 BMI = 体重(kg) / 身高(m)^2
  double? get bmi {
    if (weight == null || height == null || height == 0) return null;
    return weight! / ((height! / 100) * (height! / 100));
  }

  /// 获取 BMI 分类
  String? get bmiCategory {
    final b = bmi;
    if (b == null) return null;
    if (b < 18.5) return '偏瘦';
    if (b < 24) return '正常';
    if (b < 28) return '超重';
    return '肥胖';
  }

  BodyMetrics copyWith({
    String? id,
    DateTime? date,
    double? weight,
    double? height,
    double? bodyFatPercentage,
    double? muscleMass,
    int? basalMetabolicRate,
    String? notes,
  }) {
    return BodyMetrics(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      muscleMass: muscleMass ?? this.muscleMass,
      basalMetabolicRate: basalMetabolicRate ?? this.basalMetabolicRate,
      notes: notes ?? this.notes,
    );
  }
}
