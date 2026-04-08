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
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(WorkoutTypeAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SwimStyleAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MuscleGroupAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(SwimSetAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(GymSetAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(GymExerciseAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(WorkoutSessionAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(AppUserAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(AchievementAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(BodyMetricsAdapter());

    // Only open the users box at startup;
    // per-user workout boxes are opened lazily by UserProvider.
    try {
      await Hive.openBox<AppUser>('app_users').timeout(const Duration(seconds: 10));
    } catch (_) {
      // 打开失败不阻塞
    }
  }
}
