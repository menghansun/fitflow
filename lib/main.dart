import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/supabase_config.dart';
import 'services/hive_service.dart';
import 'services/supabase_service.dart';
import 'providers/user_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/achievement_provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/auth/login_screen.dart';
import 'widgets/achievement_unlock_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);
  await HiveService.init();
  // Supabase init — replace with your Project URL and anon key
  await SupabaseService.init(supabaseUrl, supabaseAnonKey);
  runApp(const FitFlowApp());
}

final _navigatorKey = GlobalKey<NavigatorState>();

class FitFlowApp extends StatefulWidget {
  const FitFlowApp({super.key});

  @override
  State<FitFlowApp> createState() => _FitFlowAppState();
}

class _FitFlowAppState extends State<FitFlowApp> {
  String? _loadedUserId;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..init()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
      ],
      child: StreamBuilder(
        stream: SupabaseService.authStateChanges,
        builder: (context, authSnapshot) {
          final isLoggedIn = SupabaseService.instance.uid != null;

          return Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              if (!userProvider.initialized) {
                return _buildMaterialApp(ThemeMode.system, const _SplashScreen());
              }

              // Not logged in → login screen
              if (!isLoggedIn) {
                return _buildMaterialApp(ThemeMode.system, const LoginScreen());
              }

              // Logged in → load workout data
              if (userProvider.currentUser != null) {
                final uid = userProvider.currentUser!.id;
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (_loadedUserId != uid) {
                    _loadedUserId = uid;
                    await context.read<WorkoutProvider>().loadForUser(uid);
                    if (!context.mounted) return;
                    await context.read<AchievementProvider>().init(uid);
                    // 设置成就检查回调
                    context.read<WorkoutProvider>().onSessionsChanged = () async {
                      final sessions = context.read<WorkoutProvider>().sessions;
                      final newlyUnlocked = await context.read<AchievementProvider>().checkAndUpdateAchievements(sessions);
                      final dialogContext = _navigatorKey.currentContext;
                      if (dialogContext == null) return;

                      for (final achievement in newlyUnlocked) {
                        await showAchievementUnlockDialog(dialogContext, achievement);
                      }
                    };
                    // 初始检查成就（不显示弹窗）
                    final sessions = context.read<WorkoutProvider>().sessions;
                    await context.read<AchievementProvider>().checkAndUpdateAchievements(sessions);
                  }
                });
              } else if (isLoggedIn) {
                // Supabase logged in but no local user → auto create local profile then load workouts
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await userProvider.ensureLocalProfileAfterAuth('我');
                  if (userProvider.currentUser != null) {
                    final newUid = userProvider.currentUser!.id;
                    if (_loadedUserId != newUid) {
                      _loadedUserId = newUid;
                      if (context.mounted) {
                        await context.read<WorkoutProvider>().loadForUser(newUid);
                        if (!context.mounted) return;
                        await context.read<AchievementProvider>().init(newUid);
                        // 设置成就检查回调
                        context.read<WorkoutProvider>().onSessionsChanged = () async {
                          final sessions = context.read<WorkoutProvider>().sessions;
                          final newlyUnlocked = await context.read<AchievementProvider>().checkAndUpdateAchievements(sessions);
                          final dialogContext = _navigatorKey.currentContext;
                          if (dialogContext == null) return;

                          for (final achievement in newlyUnlocked) {
                            await showAchievementUnlockDialog(dialogContext, achievement);
                          }
                        };
                        // 初始检查成就（不显示弹窗）
                        final sessions = context.read<WorkoutProvider>().sessions;
                        await context.read<AchievementProvider>().checkAndUpdateAchievements(sessions);
                      }
                    }
                  }
                });
              }

              final themeMode = userProvider.currentThemeMode;
              return _buildMaterialApp(
                themeMode,
                const MainScreen(),
              );
            },
          );
        },
      ),
    );
  }

  MaterialApp _buildMaterialApp(ThemeMode themeMode, Widget home) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'FitFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: const Locale('zh', 'CN'),
      home: home,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: const Image(
                image: AssetImage('assets/splash.gif'),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            const Text('FitFlow', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('💪 持续运动，记录成长', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
