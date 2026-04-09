import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/user_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../models/app_user.dart';
import '../../theme/app_theme.dart';
import '../../services/export_import_service.dart';
import '../../services/supabase_service.dart';
import '../gym/exercise_gallery_screen.dart';
import 'monthly_report_screen.dart';
import 'achievement_screen.dart';
import '../body_metrics/body_metrics_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static Future<void> _exportData(BuildContext context, AppUser user) async {
    try {
      await ExportImportService.export(user.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  static Future<void> _importData(BuildContext context, AppUser user, WorkoutProvider workoutProvider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      final xFile = result.files.first.xFile;
      final json = await xFile.readAsString();
      final count = await ExportImportService.importFromJson(user.id, json);
      await workoutProvider.syncAllToCloud();
      workoutProvider.refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功导入 $count 条记录并同步到云端')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: Consumer2<UserProvider, WorkoutProvider>(
        builder: (context, userProvider, workoutProvider, _) {
          final theme = Theme.of(context);
          final user = userProvider.currentUser;
          if (user == null) return const Center(child: CircularProgressIndicator());

          final totalSessions = workoutProvider.sessions.where((s) => s.countsAsWorkout).length;
          final totalMins = workoutProvider.sessions
                  .where((s) => s.countsAsWorkout)
                  .fold(
                  0, (s, w) => s + w.durationSeconds) ~/
              60;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 20),

              // ── User header ─────────────────────
              _UserHeader(user: user),

              const SizedBox(height: 20),

              // ── Stats summary ──────────────────
              _LifetimeStats(
                totalSessions: totalSessions,
                totalMins: totalMins,
              ),

              const SizedBox(height: 24),

              // ── Settings section ───────────────
              _SectionHeader('主题设置'),
              _ThemeSelector(user: user, userProvider: userProvider),

              const SizedBox(height: 20),
              _SectionHeader('账户'),

              // Edit nickname / avatar
              _SettingsTile(
                icon: Icons.edit_outlined,
                title: '编辑资料',
                subtitle: '修改昵称和头像',
                onTap: () => _showEditProfile(context, user, userProvider),
              ),

              _SettingsTile(
                icon: Icons.bar_chart_rounded,
                title: '游泳报告',
                subtitle: '查看本月训练总结',
                onTap: () {
                  final now = DateTime.now();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MonthlyReportScreen(year: now.year, month: now.month, userId: user.id),
                    ),
                  );
                },
              ),

              _SettingsTile(
                icon: Icons.emoji_events_outlined,
                title: '我的成就',
                subtitle: '查看已解锁的成就',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AchievementScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              _SectionHeader('健康'),

              _SettingsTile(
                icon: Icons.monitor_weight_outlined,
                title: '身体指标',
                subtitle: '体重、BMI、体脂率、肌肉含量等',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BodyMetricsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              _SectionHeader('健身'),

              _SettingsTile(
                icon: Icons.fitness_center_outlined,
                title: '动作库',
                subtitle: '浏览所有健身动作，支持查看示范视频',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ExerciseGalleryScreen()),
                ),
              ),

              const SizedBox(height: 20),
              _SectionHeader('数据'),

              _SettingsTile(
                icon: Icons.upload_outlined,
                title: '导出数据',
                subtitle: '将所有运动记录导出为 JSON 文件',
                onTap: () => _exportData(context, user),
              ),

              _SettingsTile(
                icon: Icons.download_outlined,
                title: '导入数据',
                subtitle: '从 JSON 文件恢复运动记录',
                onTap: () => _importData(context, user, workoutProvider),
              ),

              _SettingsTile(
                icon: Icons.cloud_upload_outlined,
                title: '同步到云端',
                subtitle: '将本地记录上传到 Supabase',
                onTap: () async {
                  try {
                    await workoutProvider.syncAllToCloud();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已同步到云端')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('同步失败: $e')),
                      );
                    }
                  }
                },
              ),

              _SettingsTile(
                icon: Icons.delete_outline,
                title: '清空本用户数据',
                subtitle: '删除所有运动记录（不可恢复）',
                iconColor: Colors.red.shade300,
                onTap: () => _confirmClear(context, workoutProvider),
              ),

              _SettingsTile(
                icon: Icons.logout,
                title: '退出登录',
                subtitle: '切换到其他账户',
                iconColor: Colors.orange,
                onTap: () => SupabaseService.logout(),
              ),

              const SizedBox(height: 40),
              Center(
                child: Text(
                  'FitFlow v1.0.0\n💪 持续运动，记录成长',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  void _showEditProfile(
      BuildContext context, AppUser user, UserProvider userProvider) {
    final nicknameCtrl = TextEditingController(text: user.nickname);
    String selectedEmoji = user.avatarEmoji ?? '💪';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx2, setModalState) => Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(ctx2).viewInsets.bottom + 32),
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha:0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('编辑资料', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha:0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(selectedEmoji,
                          style: const TextStyle(fontSize: 36)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: AppUser.defaultAvatars.map((e) {
                    final sel = selectedEmoji == e;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedEmoji = e),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: sel
                              ? theme.colorScheme.primary.withValues(alpha:0.2)
                              : (isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightBackground),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(e, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nicknameCtrl,
                  decoration: const InputDecoration(
                    labelText: '昵称',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  maxLength: 12,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nicknameCtrl.text.trim();
                      if (name.isEmpty) return;
                      user.nickname = name;
                      user.avatarEmoji = selectedEmoji;
                      await userProvider.updateUser(user);
                      if (ctx2.mounted) Navigator.pop(ctx2);
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  void _confirmClear(BuildContext context, WorkoutProvider workoutProvider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清空数据'),
        content: const Text('确定要删除所有运动记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          TextButton(
            onPressed: () async {
              await workoutProvider.clearAll();
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────────────────

class _UserHeader extends StatelessWidget {
  final AppUser user;
  const _UserHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BodyMetricsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [primary.withValues(alpha:0.25), primary.withValues(alpha:0.1)]
                : [primary.withValues(alpha:0.12), primary.withValues(alpha:0.04)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withValues(alpha:0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.3 : 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primary.withValues(alpha:0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(user.avatarEmoji ?? '💪',
                    style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nickname,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '加入 FitFlow ${_daysSince(user.createdAt)} 天',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: primary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '会员',
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  int _daysSince(DateTime date) {
    return DateTime.now().difference(date).inDays + 1;
  }
}

class _LifetimeStats extends StatelessWidget {
  final int totalSessions;
  final int totalMins;
  const _LifetimeStats(
      {required this.totalSessions, required this.totalMins});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            icon: '🏃',
            value: '$totalSessions',
            label: '总运动次数',
            color: AppColors.darkPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            icon: '⏱️',
            value: '$totalMins',
            label: '总运动分钟',
            color: AppColors.swimAccent,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const Spacer(),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final AppUser user;
  final UserProvider userProvider;

  const _ThemeSelector(
      {required this.user, required this.userProvider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final options = [
      (ThemeMode.system, '🌓', '跟随系统'),
      (ThemeMode.light, '☀️', '浅色'),
      (ThemeMode.dark, '🌙', '深色'),
    ];

    return Row(
      children: options.map((opt) {
        final (mode, emoji, label) = opt;
        final selected = user.themeModeIndex == mode.index;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => userProvider.setThemeMode(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? primary.withValues(alpha:0.15)
                      : (isDark
                          ? AppColors.darkCard
                          : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(emoji,
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(label,
                        style: TextStyle(
                          color: selected ? primary : null,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 12,
                        )),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              )),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 22,
                color: iconColor ?? theme.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  if (subtitle != null)
                    Text(subtitle!, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.textTheme.bodyMedium?.color),
          ],
        ),
      ),
    );
  }
}
