import 'package:hive_flutter/hive_flutter.dart';
import '../models/workout_session.dart';
import '../models/app_user.dart';
import '../models/achievement.dart';
import '../models/body_metrics.dart';

class HiveService {
  static Future<void> init() async {
    try {
      await Hive.initFlutter().timeout(const Duration(seconds: 10));
    } catch (_) {
      // Web 或其他平台初始化失败不阻塞启动
      return;
    }

    // Adapters
    Hive.registerAdapter(WorkoutTypeAdapter());
    Hive.registerAdapter(SwimStyleAdapter());
    Hive.registerAdapter(MuscleGroupAdapter());
    Hive.registerAdapter(SwimSetAdapter());
    Hive.registerAdapter(GymSetAdapter());
    Hive.registerAdapter(GymExerciseAdapter());
    Hive.registerAdapter(WorkoutSessionAdapter());
    Hive.registerAdapter(AppUserAdapter());
    Hive.registerAdapter(AchievementAdapter());
    Hive.registerAdapter(BodyMetricsAdapter());

    // Only open the users box at startup;
    // per-user workout boxes are opened lazily by UserProvider.
    try {
      await Hive.openBox<AppUser>('app_users').timeout(const Duration(seconds: 10));
    } catch (_) {
      // 打开失败不阻塞
    }
  }
}
