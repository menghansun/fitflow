import 'package:hive/hive.dart';

part 'achievement.g.dart';

enum AchievementType {
  // 游泳类
  swimFirst,
  swim10,
  swim50,
  swim100,
  swimDistance10,
  swimDistance50,
  swimDistance100,

  // 健身类
  gymFirst,
  gym10,
  gym50,

  // 连续运动类
  streak3,
  streak7,
  streak30,
  lazy3,  // 连续3天不运动

  // 月度类
  monthlySwim5,
  monthlyWorkout10,

  // 热量类
  burn100,        // 单次消耗100大卡
  calorie1000,    // 累计消耗1000大卡

  // 时长类
  endurance30,    // 单次运动30分钟
  ironMan,       // 单次运动60分钟

  // 部位类
  core10,        // 完成10次腹部训练
  legs10,        // 完成10次腿部训练
  upperBody10,   // 完成10次上肢训练

  // 全能类
  allRounder,    // 完成5种不同类型运动

  // 泳姿类
  freestyleUnlocked,  // 解锁自由泳
}

@HiveType(typeId: 10)
class Achievement extends HiveObject {
  @HiveField(0)
  final String typeString;

  @HiveField(1)
  int currentValue;

  @HiveField(2)
  bool unlocked;

  @HiveField(3)
  DateTime? unlockedAt;

  Achievement({
    required this.typeString,
    this.currentValue = 0,
    this.unlocked = false,
    this.unlockedAt,
  });

  AchievementType get type => AchievementType.values.firstWhere(
    (e) => e.name == typeString,
    orElse: () => AchievementType.swimFirst,
  );

  String get title {
    switch (type) {
      // 游泳
      case AchievementType.swimFirst:
        return '初出茅庐';
      case AchievementType.swim10:
        return '十泳目标';
      case AchievementType.swim50:
        return '五十泳将';
      case AchievementType.swim100:
        return '百泳大师';
      case AchievementType.swimDistance10:
        return '十公里突破';
      case AchievementType.swimDistance50:
        return '五十公里成就';
      case AchievementType.swimDistance100:
        return '百公里传奇';
      // 健身
      case AchievementType.gymFirst:
        return '健身首秀';
      case AchievementType.gym10:
        return '健身达人';
      case AchievementType.gym50:
        return '健身王者';
      // 连续
      case AchievementType.streak3:
        return '三日连击';
      case AchievementType.streak7:
        return '一周坚持';
      case AchievementType.streak30:
        return '月度坚持';
      case AchievementType.lazy3:
        return '躺平达人';
      // 月度
      case AchievementType.monthlySwim5:
        return '月度泳者';
      case AchievementType.monthlyWorkout10:
        return '月度运动家';
      // 热量
      case AchievementType.burn100:
        return '燃脂小能手';
      case AchievementType.calorie1000:
        return '卡路里富翁';
      // 时长
      case AchievementType.endurance30:
        return '耐力王者';
      case AchievementType.ironMan:
        return '铁人';
      // 部位
      case AchievementType.core10:
        return '核心强者';
      case AchievementType.legs10:
        return '下肢强人';
      case AchievementType.upperBody10:
        return '上肢霸主';
      // 全能
      case AchievementType.allRounder:
        return '全能选手';
      // 泳姿
      case AchievementType.freestyleUnlocked:
        return '自由泳选手';
    }
  }

  String get description {
    switch (type) {
      // 游泳
      case AchievementType.swimFirst:
        return '完成第一次游泳';
      case AchievementType.swim10:
        return '累计游泳10次';
      case AchievementType.swim50:
        return '累计游泳50次';
      case AchievementType.swim100:
        return '累计游泳100次';
      case AchievementType.swimDistance10:
        return '累计游泳10公里';
      case AchievementType.swimDistance50:
        return '累计游泳50公里';
      case AchievementType.swimDistance100:
        return '累计游泳100公里';
      // 健身
      case AchievementType.gymFirst:
        return '完成第一次健身';
      case AchievementType.gym10:
        return '累计健身10次';
      case AchievementType.gym50:
        return '累计健身50次';
      // 连续
      case AchievementType.streak3:
        return '连续运动3天';
      case AchievementType.streak7:
        return '连续运动7天';
      case AchievementType.streak30:
        return '连续运动30天';
      case AchievementType.lazy3:
        return '连续3天不运动';
      // 月度
      case AchievementType.monthlySwim5:
        return '单月游泳5次';
      case AchievementType.monthlyWorkout10:
        return '单月运动10次';
      // 热量
      case AchievementType.burn100:
        return '单次消耗100大卡';
      case AchievementType.calorie1000:
        return '累计消耗1000大卡';
      // 时长
      case AchievementType.endurance30:
        return '单次运动30分钟';
      case AchievementType.ironMan:
        return '单次运动60分钟';
      // 部位
      case AchievementType.core10:
        return '完成10次腹部训练';
      case AchievementType.legs10:
        return '完成10次腿部训练';
      case AchievementType.upperBody10:
        return '完成10次上肢训练';
      // 全能
      case AchievementType.allRounder:
        return '完成5种不同类型运动';
      // 泳姿
      case AchievementType.freestyleUnlocked:
        return '解锁自由泳';
    }
  }

  String get icon {
    switch (type) {
      // 游泳
      case AchievementType.swimFirst:
      case AchievementType.swim10:
      case AchievementType.swim50:
      case AchievementType.swim100:
        return '🏊';
      case AchievementType.swimDistance10:
      case AchievementType.swimDistance50:
      case AchievementType.swimDistance100:
        return '🌊';
      // 健身
      case AchievementType.gymFirst:
      case AchievementType.gym10:
      case AchievementType.gym50:
        return '💪';
      // 连续
      case AchievementType.streak3:
      case AchievementType.streak7:
      case AchievementType.streak30:
        return '🔥';
      case AchievementType.lazy3:
        return '😴';
      // 月度
      case AchievementType.monthlySwim5:
      case AchievementType.monthlyWorkout10:
        return '📅';
      // 热量
      case AchievementType.burn100:
      case AchievementType.calorie1000:
        return '🔥';
      // 时长
      case AchievementType.endurance30:
      case AchievementType.ironMan:
        return '⏱️';
      // 部位
      case AchievementType.core10:
      case AchievementType.legs10:
      case AchievementType.upperBody10:
        return '🎯';
      // 全能
      case AchievementType.allRounder:
        return '🏅';
      // 泳姿
      case AchievementType.freestyleUnlocked:
        return '🏊';
    }
  }

  String get joke {
    switch (type) {
      // 游泳
      case AchievementType.swimFirst:
        return '游泳就和呼吸一样简单！🏊';
      case AchievementType.swim10:
        return '游泳是一个人的兵荒马乱！💪';
      case AchievementType.swim50:
        return '天吶！五十米池对你轻轻松松了吧🌊';
      case AchievementType.swim100:
        return '百次游泳里程碑！你就是水中蛟龙！🐉';
      case AchievementType.swimDistance10:
        return '十公里达成！相当于游了400圈！🏅';
      case AchievementType.swimDistance50:
        return '五十公里！可以横渡海峡了！🌊';
      case AchievementType.swimDistance100:
        return '百公里传奇！国家队没你真是他们的损失！🏆';
      // 健身
      case AchievementType.gymFirst:
        return '第一次健身！挥洒汗水的开始！💪';
      case AchievementType.gym10:
        return '十次健身达成！越来越强了！🔥';
      case AchievementType.gym50:
        return '五十次健身！健身房里你最帅！😎';
      // 连续
      case AchievementType.streak3:
        return '三日连击！I am 思壮！🔥';
      case AchievementType.streak7:
        return '一周坚持！回本了回本了！⏰';
      case AchievementType.streak30:
        return 'umbelievable🏆这你都能完成';
      case AchievementType.lazy3:
        return '你完全不运动的是吗？😴';
      // 月度
      case AchievementType.monthlySwim5:
        return '浅水区小酌！~🌟';
      case AchievementType.monthlyWorkout10:
        return '深水区畅饮！~🎯';
      // 热量
      case AchievementType.burn100:
        return '百卡燃烧！也就一个蛋挞！🔥';
      case AchievementType.calorie1000:
        return '千卡成就！卡路里富翁在此！💰';
      // 时长
      case AchievementType.endurance30:
        return '三十分钟耐力！意志力的胜利！⏱️';
      case AchievementType.ironMan:
        return '铁人诞生！你运动了一个小时耶！🏅';
      // 部位
      case AchievementType.core10:
        return '核心强化！召唤马甲线！🎯';
      case AchievementType.legs10:
        return '痛！好痛💪';
      case AchievementType.upperBody10:
        return '肌肉没涨，但是还是累到了呢~！💪';
      // 全能
      case AchievementType.allRounder:
        return '汗流浃背了吧！🏅';
      // 泳姿
      case AchievementType.freestyleUnlocked:
        return '喝饱了吧~~~！🏊';
    }
  }

  int get targetValue {
    switch (type) {
      case AchievementType.swimFirst:
      case AchievementType.gymFirst:
        return 1;
      case AchievementType.swim10:
      case AchievementType.gym10:
      case AchievementType.streak3:
      case AchievementType.monthlySwim5:
        return 10;
      case AchievementType.swim50:
      case AchievementType.gym50:
      case AchievementType.streak7:
      case AchievementType.endurance30:
      case AchievementType.core10:
      case AchievementType.legs10:
      case AchievementType.upperBody10:
        return 50;
      case AchievementType.lazy3:
        return 3;
      case AchievementType.swim100:
      case AchievementType.streak30:
      case AchievementType.burn100:
        return 100;
      case AchievementType.swimDistance10:
        return 10;
      case AchievementType.swimDistance50:
      case AchievementType.calorie1000:
        return 50;
      case AchievementType.swimDistance100:
        return 100;
      case AchievementType.monthlyWorkout10:
        return 10;
      case AchievementType.ironMan:
        return 60;
      case AchievementType.allRounder:
        return 5;
      case AchievementType.freestyleUnlocked:
        return 1;
    }
  }

  double get progress {
    if (targetValue == 0) return 0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  static List<AchievementType> get allTypes => AchievementType.values;
}

// 成就定义常量
class AchievementDefinition {
  static const String categorySwim = '游泳';
  static const String categoryGym = '健身';
  static const String categoryStreak = '连续';
  static const String categoryMonthly = '月度';
  static const String categoryCalorie = '热量';
  static const String categoryDuration = '时长';
  static const String categoryMuscle = '部位';
  static const String categoryVariety = '全能';

  static String getCategory(AchievementType type) {
    switch (type) {
      // 游泳
      case AchievementType.swimFirst:
      case AchievementType.swim10:
      case AchievementType.swim50:
      case AchievementType.swim100:
      case AchievementType.swimDistance10:
      case AchievementType.swimDistance50:
      case AchievementType.swimDistance100:
      case AchievementType.freestyleUnlocked:
        return categorySwim;
      // 健身
      case AchievementType.gymFirst:
      case AchievementType.gym10:
      case AchievementType.gym50:
        return categoryGym;
      // 连续
      case AchievementType.streak3:
      case AchievementType.streak7:
      case AchievementType.streak30:
      case AchievementType.lazy3:
        return categoryStreak;
      // 月度
      case AchievementType.monthlySwim5:
      case AchievementType.monthlyWorkout10:
        return categoryMonthly;
      // 热量
      case AchievementType.burn100:
      case AchievementType.calorie1000:
        return categoryCalorie;
      // 时长
      case AchievementType.endurance30:
      case AchievementType.ironMan:
        return categoryDuration;
      // 部位
      case AchievementType.core10:
      case AchievementType.legs10:
      case AchievementType.upperBody10:
        return categoryMuscle;
      // 全能
      case AchievementType.allRounder:
        return categoryVariety;
    }
  }

  static List<AchievementType> getTypesByCategory(String category) {
    return AchievementType.values
        .where((t) => getCategory(t) == category)
        .toList();
  }
}
