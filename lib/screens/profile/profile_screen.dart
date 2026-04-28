import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/user_provider.dart';
import '../../providers/workout_provider.dart';
import '../../services/export_import_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../body_metrics/body_metrics_screen.dart';
import '../gym/exercise_gallery_screen.dart';
import 'achievement_screen.dart';
import 'monthly_report_screen.dart';
import 'training_plan_screen.dart';

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

  static Future<void> _importData(
    BuildContext context,
    AppUser user,
    WorkoutProvider workoutProvider,
  ) async {
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
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: const Color(0xFFF4F7FB),
      ),
      body: Consumer2<UserProvider, WorkoutProvider>(
        builder: (context, userProvider, workoutProvider, _) {
          final theme = Theme.of(context);
          final user = userProvider.currentUser;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalSessions =
              workoutProvider.sessions.where((s) => s.countsAsWorkout).length;
          final totalMins = workoutProvider.sessions
                  .where((s) => s.countsAsWorkout)
                  .fold<int>(0, (sum, item) => sum + item.durationSeconds) ~/
              60;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              _HeroProfileCard(
                user: user,
                totalSessions: totalSessions,
                totalMins: totalMins,
                onTapEdit: () => _showEditProfile(context, user, userProvider),
              ),
              const SizedBox(height: 12),
              _ProfileGroupCard(
                title: '账户',
                children: [
                  _ProfileMenuTile(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF4F46E5),
                    title: '编辑资料',
                    subtitle: '修改昵称、头像和身高',
                    onTap: () => _showEditProfile(context, user, userProvider),
                  ),
                  _ProfileMenuTile(
                    icon: Icons.assignment_outlined,
                    color: const Color(0xFF4F46E5),
                    title: '训练计划',
                    subtitle: '根据目标查看本周安排和今日建议',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrainingPlanScreen(),
                        ),
                      );
                    },
                  ),
                  _ProfileMenuTile(
                    icon: Icons.bar_chart_rounded,
                    color: const Color(0xFF0EA5E9),
                    title: '游泳报告',
                    subtitle: '查看本月训练总结',
                    onTap: () {
                      final now = DateTime.now();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MonthlyReportScreen(
                            year: now.year,
                            month: now.month,
                            userId: user.id,
                          ),
                        ),
                      );
                    },
                  ),
                  _ProfileMenuTile(
                    icon: Icons.emoji_events_outlined,
                    color: const Color(0xFFF59E0B),
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
                ],
              ),
              const SizedBox(height: 14),
              _ProfileGroupCard(
                title: '健康',
                children: [
                  _ProfileMenuTile(
                    icon: Icons.monitor_weight_outlined,
                    color: const Color(0xFF14B8A6),
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
                ],
              ),
              const SizedBox(height: 14),
              _ProfileGroupCard(
                title: '健身',
                children: [
                  _ProfileMenuTile(
                    icon: Icons.fitness_center_outlined,
                    color: AppColors.gymAccent,
                    title: '动作库',
                    subtitle: '浏览所有健身动作，支持查看示范视频',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ExerciseGalleryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ProfileGroupCard(
                title: '数据',
                children: [
                  _ProfileMenuTile(
                    icon: Icons.upload_outlined,
                    color: const Color(0xFF10B981),
                    title: '导出数据',
                    subtitle: '将所有运动记录导出为 JSON 文件',
                    onTap: () => _exportData(context, user),
                  ),
                  _ProfileMenuTile(
                    icon: Icons.download_outlined,
                    color: const Color(0xFF8B5CF6),
                    title: '导入数据',
                    subtitle: '从 JSON 文件恢复运动记录',
                    onTap: () => _importData(context, user, workoutProvider),
                  ),
                  _ProfileMenuTile(
                    icon: Icons.cloud_upload_outlined,
                    color: const Color(0xFF14B8A6),
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
                  _ProfileMenuTile(
                    icon: Icons.delete_outline,
                    color: Colors.red.shade300,
                    title: '清空本用户数据',
                    subtitle: '删除所有运动记录（不可恢复）',
                    onTap: () => _confirmClear(context, workoutProvider),
                  ),
                  _ProfileMenuTile(
                    icon: Icons.logout,
                    color: Colors.orange,
                    title: '退出登录',
                    subtitle: '切换到其他账户',
                    onTap: () => SupabaseService.logout(),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  'FitFlow v1.0.0\n持续运动，记录成长',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditProfile(
    BuildContext context,
    AppUser user,
    UserProvider userProvider,
  ) {
    final nicknameCtrl = TextEditingController(text: user.nickname);
    final heightCtrl = TextEditingController(text: user.height?.toString() ?? '');
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(ctx2).viewInsets.bottom + 32,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('编辑资料', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          selectedEmoji,
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppUser.defaultAvatars.map((emoji) {
                      final selected = selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedEmoji = emoji),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                : (isDark ? AppColors.darkCard : AppColors.lightBackground),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(emoji, style: const TextStyle(fontSize: 22)),
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: heightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '身高 (cm)',
                      prefixIcon: Icon(Icons.height),
                    ),
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
                        user.height = double.tryParse(heightCtrl.text);
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
            child: const Text('取消'),
          ),
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

class _HeroProfileCard extends StatelessWidget {
  final AppUser user;
  final int totalSessions;
  final int totalMins;
  final VoidCallback onTapEdit;

  const _HeroProfileCard({
    required this.user,
    required this.totalSessions,
    required this.totalMins,
    required this.onTapEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BodyMetricsScreen(),
                  ),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  child: Text(
                    user.avatarEmoji ?? '💪',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BodyMetricsScreen(),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nickname,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '持续运动第 ${_daysSince(user.createdAt)} 天',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: onTapEdit,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.edit_outlined, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ProfileTopStat(
                  value: user.height != null ? user.height!.toStringAsFixed(0) : '--',
                  label: '身高',
                ),
              ),
              Expanded(
                child: _ProfileTopStat(value: '$totalSessions', label: '累计训练'),
              ),
              Expanded(
                child: _ProfileTopStat(value: '$totalMins', label: '总分钟'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _daysSince(DateTime date) {
    return DateTime.now().difference(date).inDays + 1;
  }
}

class _ProfileTopStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileTopStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ProfileGroupCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileGroupCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _ProfileMenuTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
