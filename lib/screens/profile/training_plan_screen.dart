import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/body_metrics.dart';
import '../../models/workout_session.dart';
import '../../providers/body_metrics_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/workout_provider.dart';
import '../../theme/app_theme.dart';

enum _TrainingGoalType {
  fatLoss,
  muscleGain,
  endurance,
  strength,
  swimPerformance,
  consistency,
}

enum _PlanSessionKind {
  gymUpper,
  gymLower,
  gymPush,
  gymPull,
  gymFullBody,
  coreMobility,
  cardioSteady,
  cardioIntervals,
  swimTechnique,
  swimEndurance,
  recovery,
  rest,
}

class _GoalConfig {
  final _TrainingGoalType goalType;
  final int trainingDaysPerWeek;
  final double? targetWeightKg;
  final double? targetBodyFatPercentage;
  final double? targetMuscleMassKg;
  final double? targetMonthlyDistanceKm;
  final int? targetStreakDays;

  const _GoalConfig({
    required this.goalType,
    required this.trainingDaysPerWeek,
    this.targetWeightKg,
    this.targetBodyFatPercentage,
    this.targetMuscleMassKg,
    this.targetMonthlyDistanceKm,
    this.targetStreakDays,
  });

  factory _GoalConfig.initial() {
    return const _GoalConfig(
      goalType: _TrainingGoalType.consistency,
      trainingDaysPerWeek: 4,
      targetMonthlyDistanceKm: 20,
      targetStreakDays: 14,
    );
  }

  _GoalConfig copyWith({
    _TrainingGoalType? goalType,
    int? trainingDaysPerWeek,
    double? targetWeightKg,
    bool clearTargetWeightKg = false,
    double? targetBodyFatPercentage,
    bool clearTargetBodyFatPercentage = false,
    double? targetMuscleMassKg,
    bool clearTargetMuscleMassKg = false,
    double? targetMonthlyDistanceKm,
    bool clearTargetMonthlyDistanceKm = false,
    int? targetStreakDays,
    bool clearTargetStreakDays = false,
  }) {
    return _GoalConfig(
      goalType: goalType ?? this.goalType,
      trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
      targetWeightKg: clearTargetWeightKg
          ? null
          : (targetWeightKg ?? this.targetWeightKg),
      targetBodyFatPercentage: clearTargetBodyFatPercentage
          ? null
          : (targetBodyFatPercentage ?? this.targetBodyFatPercentage),
      targetMuscleMassKg: clearTargetMuscleMassKg
          ? null
          : (targetMuscleMassKg ?? this.targetMuscleMassKg),
      targetMonthlyDistanceKm: clearTargetMonthlyDistanceKm
          ? null
          : (targetMonthlyDistanceKm ?? this.targetMonthlyDistanceKm),
      targetStreakDays: clearTargetStreakDays
          ? null
          : (targetStreakDays ?? this.targetStreakDays),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goalType': goalType.name,
      'trainingDaysPerWeek': trainingDaysPerWeek,
      'targetWeightKg': targetWeightKg,
      'targetBodyFatPercentage': targetBodyFatPercentage,
      'targetMuscleMassKg': targetMuscleMassKg,
      'targetMonthlyDistanceKm': targetMonthlyDistanceKm,
      'targetStreakDays': targetStreakDays,
    };
  }

  factory _GoalConfig.fromJson(Map<String, dynamic> json) {
    final goalTypeName = json['goalType'] as String?;
    return _GoalConfig(
      goalType: _TrainingGoalType.values.firstWhere(
        (item) => item.name == goalTypeName,
        orElse: () => _TrainingGoalType.consistency,
      ),
      trainingDaysPerWeek: (json['trainingDaysPerWeek'] as num?)?.toInt() ?? 4,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      targetBodyFatPercentage:
          (json['targetBodyFatPercentage'] as num?)?.toDouble(),
      targetMuscleMassKg: (json['targetMuscleMassKg'] as num?)?.toDouble(),
      targetMonthlyDistanceKm:
          (json['targetMonthlyDistanceKm'] as num?)?.toDouble(),
      targetStreakDays: (json['targetStreakDays'] as num?)?.toInt(),
    );
  }
}

class _GoalProgress {
  final String title;
  final String currentLabel;
  final String targetLabel;
  final double ratio;
  final String hint;

  const _GoalProgress({
    required this.title,
    required this.currentLabel,
    required this.targetLabel,
    required this.ratio,
    required this.hint,
  });
}

class _ActionItem {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _ActionItem({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}

class _PlanSuggestion {
  final String title;
  final String subtitle;
  final String intensity;
  final Color color;
  final IconData icon;

  const _PlanSuggestion({
    required this.title,
    required this.subtitle,
    required this.intensity,
    required this.color,
    required this.icon,
  });
}

class _PlannedDay {
  final DateTime date;
  final _PlanSessionKind kind;
  final String title;
  final String detail;
  final String durationLabel;
  final Color color;
  final IconData icon;

  const _PlannedDay({
    required this.date,
    required this.kind,
    required this.title,
    required this.detail,
    required this.durationLabel,
    required this.color,
    required this.icon,
  });
}

class TrainingPlanScreen extends StatefulWidget {
  const TrainingPlanScreen({super.key});

  @override
  State<TrainingPlanScreen> createState() => _TrainingPlanScreenState();
}

class _TrainingPlanScreenState extends State<TrainingPlanScreen> {
  static const _prefsKeyPrefix = 'training_goal_config_v2';

  _GoalConfig _config = _GoalConfig.initial();
  bool _loading = true;
  String? _loadedUserId;

  Future<void> _loadConfig(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefsKeyPrefix:$userId');
    if (!mounted || _loadedUserId != userId) return;
    setState(() {
      if (raw != null) {
        try {
          _config = _GoalConfig.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          );
        } catch (_) {
          _config = _GoalConfig.initial();
        }
      }
      _loading = false;
    });
  }

  Future<void> _saveConfig(String userId, _GoalConfig config) async {
    setState(() {
      _config = config;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsKeyPrefix:$userId',
      jsonEncode(config.toJson()),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.read<UserProvider>().currentUser?.id;
    if (userId == null) return;
    if (_loadedUserId == userId && !_loading) return;
    _loadedUserId = userId;
    _loading = true;
    _config = _GoalConfig.initial();
    _loadConfig(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserProvider, WorkoutProvider, BodyMetricsProvider>(
      builder: (context, userProvider, workoutProvider, bodyMetricsProvider, _) {
        final user = userProvider.currentUser;
        if (user == null || _loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final metrics = bodyMetricsProvider.latest;
        final sessions = workoutProvider.sessions
            .where((session) => session.countsAsWorkout)
            .toList();
        final now = DateTime.now();
        final weekStart = _startOfWeek(now);
        final weekEnd = weekStart.add(const Duration(days: 6));
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);

        final weeklySessions = workoutProvider.sessionsInPeriod(weekStart, weekEnd);
        final monthlySessions = workoutProvider.sessionsInPeriod(monthStart, monthEnd);
        final progress = _buildGoalProgress(
          config: _config,
          metrics: metrics,
          workoutProvider: workoutProvider,
          monthlySessions: monthlySessions,
        );
        final suggestion = _buildTodaySuggestion(
          config: _config,
          sessions: sessions,
          weeklySessions: weeklySessions,
        );
        final weeklyPlan = _buildWeeklyPlan(
          now: now,
          config: _config,
          sessions: sessions,
        );
        final actions = _buildActionItems(
          config: _config,
          metrics: metrics,
          weeklySessions: weeklySessions,
          monthlySessions: monthlySessions,
          workoutProvider: workoutProvider,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FB),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('训练计划'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroCard(
                  config: _config,
                  weeklySessions: weeklySessions.length,
                  streak: workoutProvider.currentStreak,
                  onEdit: () => _showGoalEditor(context, user.id, _config),
                ),
                const SizedBox(height: 16),
                _SectionTitle(
                  title: '目标进度',
                  subtitle: progress.hint,
                ),
                const SizedBox(height: 12),
                _ProgressCard(progress: progress),
                const SizedBox(height: 16),
                _SectionTitle(
                  title: '今日建议',
                  subtitle: '根据最近 4 周训练结构和本周完成度动态生成',
                ),
                const SizedBox(height: 12),
                _SuggestionCard(suggestion: suggestion),
                const SizedBox(height: 16),
                _SectionTitle(
                  title: '本周安排',
                  subtitle:
                      '目标 ${_goalLabel(_config.goalType)} · 每周 ${_config.trainingDaysPerWeek} 天',
                ),
                const SizedBox(height: 12),
                ...weeklyPlan.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlannedDayCard(day: item),
                    )),
                const SizedBox(height: 16),
                _SectionTitle(
                  title: '执行重点',
                  subtitle: '优先修补当前最影响目标推进的短板',
                ),
                const SizedBox(height: 12),
                ...actions.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ActionCard(item: item),
                    )),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showGoalEditor(
    BuildContext context,
    String userId,
    _GoalConfig currentConfig,
  ) async {
    final theme = Theme.of(context);
    _TrainingGoalType selectedGoal = currentConfig.goalType;
    double days = currentConfig.trainingDaysPerWeek.toDouble();
    final weightController = TextEditingController(
      text: currentConfig.targetWeightKg?.toStringAsFixed(1) ?? '',
    );
    final bodyFatController = TextEditingController(
      text: currentConfig.targetBodyFatPercentage?.toStringAsFixed(1) ?? '',
    );
    final muscleController = TextEditingController(
      text: currentConfig.targetMuscleMassKg?.toStringAsFixed(1) ?? '',
    );
    final distanceController = TextEditingController(
      text: currentConfig.targetMonthlyDistanceKm?.toStringAsFixed(0) ?? '',
    );
    final streakController = TextEditingController(
      text: currentConfig.targetStreakDays?.toString() ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '训练目标设置',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '目标会影响今日建议和周计划结构。',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _TrainingGoalType.values.map((goal) {
                          final selected = selectedGoal == goal;
                          return ChoiceChip(
                            label: Text(_goalLabel(goal)),
                            selected: selected,
                            onSelected: (_) {
                              setSheetState(() {
                                selectedGoal = goal;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '每周训练天数 ${days.round()} 天',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Slider(
                        value: days,
                        min: 2,
                        max: 6,
                        divisions: 4,
                        label: '${days.round()}',
                        onChanged: (value) {
                          setSheetState(() {
                            days = value;
                          });
                        },
                      ),
                      _GoalEditorFields(
                        selectedGoal: selectedGoal,
                        weightController: weightController,
                        bodyFatController: bodyFatController,
                        muscleController: muscleController,
                        distanceController: distanceController,
                        streakController: streakController,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final nextConfig = _GoalConfig(
                              goalType: selectedGoal,
                              trainingDaysPerWeek: days.round(),
                              targetWeightKg:
                                  double.tryParse(weightController.text.trim()),
                              targetBodyFatPercentage:
                                  double.tryParse(bodyFatController.text.trim()),
                              targetMuscleMassKg:
                                  double.tryParse(muscleController.text.trim()),
                              targetMonthlyDistanceKm:
                                  double.tryParse(distanceController.text.trim()),
                              targetStreakDays:
                                  int.tryParse(streakController.text.trim()),
                            );
                            await _saveConfig(userId, nextConfig);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          child: const Text('保存计划'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

DateTime _startOfWeek(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

_GoalProgress _buildGoalProgress({
  required _GoalConfig config,
  required BodyMetrics? metrics,
  required WorkoutProvider workoutProvider,
  required List<WorkoutSession> monthlySessions,
}) {
  switch (config.goalType) {
    case _TrainingGoalType.fatLoss:
      final currentWeight = metrics?.weight;
      final targetWeight = config.targetWeightKg;
      if (currentWeight != null && targetWeight != null) {
        final baseline = (currentWeight > targetWeight ? currentWeight : targetWeight) + 3;
        final ratio = ((baseline - currentWeight) / (baseline - targetWeight))
            .clamp(0.0, 1.0);
        return _GoalProgress(
          title: '减脂体重目标',
          currentLabel: '${currentWeight.toStringAsFixed(1)} kg',
          targetLabel: '${targetWeight.toStringAsFixed(1)} kg',
          ratio: ratio,
          hint: '如果你也记录体脂率，这个目标会更可靠。',
        );
      }
      final monthlyMinutes = monthlySessions.fold<int>(
        0,
        (sum, session) => sum + session.durationInMinutes,
      );
      final targetMinutes = config.trainingDaysPerWeek * 45 * 4;
      return _GoalProgress(
        title: '减脂执行进度',
        currentLabel: '$monthlyMinutes 分钟',
        targetLabel: '$targetMinutes 分钟',
        ratio: (monthlyMinutes / targetMinutes).clamp(0.0, 1.0),
        hint: '未设置目标体重，当前按本月有效训练时长跟踪。',
      );
    case _TrainingGoalType.muscleGain:
      final currentMuscle = metrics?.muscleMass;
      final targetMuscle = config.targetMuscleMassKg;
      if (currentMuscle != null && targetMuscle != null) {
        final baseline = currentMuscle - 2 <= 0 ? currentMuscle : currentMuscle - 2;
        final ratio = ((currentMuscle - baseline) / (targetMuscle - baseline))
            .clamp(0.0, 1.0);
        return _GoalProgress(
          title: '增肌目标',
          currentLabel: '${currentMuscle.toStringAsFixed(1)} kg',
          targetLabel: '${targetMuscle.toStringAsFixed(1)} kg',
          ratio: ratio,
          hint: '建议每 2 到 4 周补一条身体指标记录。',
        );
      }
      final thisWeek = workoutProvider
          .sessionsInPeriod(
            _startOfWeek(DateTime.now()),
            _startOfWeek(DateTime.now()).add(const Duration(days: 6)),
          )
          .where((session) => session.type == WorkoutType.gym)
          .length;
      return _GoalProgress(
        title: '增肌执行进度',
        currentLabel: '$thisWeek 次力量训练',
        targetLabel: '${config.trainingDaysPerWeek} 次/周',
        ratio: (thisWeek / config.trainingDaysPerWeek).clamp(0.0, 1.0),
        hint: '未设置肌肉量目标，当前按周训练频率跟踪。',
      );
    case _TrainingGoalType.endurance:
    case _TrainingGoalType.swimPerformance:
      final currentDistanceKm = monthlySessions.fold<double>(
            0,
            (sum, session) => sum + ((session.totalDistanceMeters ?? 0) / 1000),
          );
      final targetKm = config.targetMonthlyDistanceKm ?? 20;
      return _GoalProgress(
        title: config.goalType == _TrainingGoalType.swimPerformance
            ? '月游泳距离目标'
            : '月耐力距离目标',
        currentLabel: '${currentDistanceKm.toStringAsFixed(1)} km',
        targetLabel: '${targetKm.toStringAsFixed(0)} km',
        ratio: (currentDistanceKm / targetKm).clamp(0.0, 1.0),
        hint: '按本月累计距离跟踪，适合跑步、骑行、游泳。',
      );
    case _TrainingGoalType.strength:
      final gymSessions = workoutProvider
          .sessionsInPeriod(
            _startOfWeek(DateTime.now()),
            _startOfWeek(DateTime.now()).add(const Duration(days: 6)),
          )
          .where((session) => session.type == WorkoutType.gym)
          .length;
      return _GoalProgress(
        title: '力量训练频率',
        currentLabel: '$gymSessions 次',
        targetLabel: '${config.trainingDaysPerWeek} 次/周',
        ratio: (gymSessions / config.trainingDaysPerWeek).clamp(0.0, 1.0),
        hint: '力量提升先看频率稳定，再看负重和动作质量。',
      );
    case _TrainingGoalType.consistency:
      final streak = workoutProvider.currentStreak;
      final target = config.targetStreakDays ?? 14;
      return _GoalProgress(
        title: '连续打卡目标',
        currentLabel: '$streak 天',
        targetLabel: '$target 天',
        ratio: (streak / target).clamp(0.0, 1.0),
        hint: '连续性目标更看重低门槛、稳定完成。',
      );
  }
}

_PlanSuggestion _buildTodaySuggestion({
  required _GoalConfig config,
  required List<WorkoutSession> sessions,
  required List<WorkoutSession> weeklySessions,
}) {
  final today = DateTime.now();
  final trainedToday = sessions.any(
    (session) =>
        session.date.year == today.year &&
        session.date.month == today.month &&
        session.date.day == today.day,
  );
  final trainedYesterday = sessions.any(
    (session) {
      final date = today.subtract(const Duration(days: 1));
      return session.date.year == date.year &&
          session.date.month == date.month &&
          session.date.day == date.day;
    },
  );
  final remaining = (config.trainingDaysPerWeek - weeklySessions.length).clamp(0, 7);
  final recentTypes = sessions.take(6).map((item) => item.type).toList();
  final lastType = recentTypes.isEmpty ? null : recentTypes.first;
  final lastGymFocus = _lastGymFocus(sessions);
  final nextGymFocus = _nextGymFocus(sessions, config.goalType);

  if (trainedToday) {
    return const _PlanSuggestion(
      title: '今天以恢复为主',
      subtitle: '你今天已经完成训练，优先补水、拉伸 10 分钟，避免重复加量。',
      intensity: '恢复',
      color: Color(0xFF34C759),
      icon: Icons.self_improvement,
    );
  }

  if (remaining == 0) {
    return const _PlanSuggestion(
      title: '本周任务已完成',
      subtitle: '可以安排轻松散步、拉伸或完全休息，重点是让下周继续稳定。',
      intensity: '低',
      color: Color(0xFF34C759),
      icon: Icons.celebration_outlined,
    );
  }

  switch (config.goalType) {
    case _TrainingGoalType.fatLoss:
      return _PlanSuggestion(
        title: trainedYesterday ? '轻中强度有氧 + 核心' : '优先做一节燃脂训练',
        subtitle: trainedYesterday
            ? '昨天已训练，今天做 30 到 40 分钟快走、椭圆机或骑行，再加 8 分钟核心。'
            : '建议 20 分钟力量循环 + 20 分钟稳态有氧，先保留强度再拉长时长。',
        intensity: '中',
        color: AppColors.cardioAccent,
        icon: Icons.local_fire_department_outlined,
      );
    case _TrainingGoalType.muscleGain:
      final title = '今天主练 ${_gymFocusLabel(nextGymFocus)}';
      final subtitle = lastType == WorkoutType.gym
          ? '上一节偏向 ${_gymFocusLabel(lastGymFocus)}，今天切到 ${_gymFocusLabel(nextGymFocus)}，避免同肌群连续堆量。'
          : '建议围绕 ${_gymFocusLabel(nextGymFocus)} 做 1 个主项 + 2 到 3 个辅助动作，周内留一次拉伸放松。';
      return _PlanSuggestion(
        title: title,
        subtitle: subtitle,
        intensity: '中高',
        color: AppColors.gymAccent,
        icon: Icons.fitness_center,
      );
    case _TrainingGoalType.endurance:
      return const _PlanSuggestion(
        title: '做一节可持续的耐力课',
        subtitle: '今天优先稳态心肺 40 到 60 分钟。若本周只有一次有氧，再加 4 组短间歇。',
        intensity: '中',
        color: AppColors.cardioAccent,
        icon: Icons.directions_run,
      );
    case _TrainingGoalType.strength:
      return _PlanSuggestion(
        title: '今天主练 ${_gymFocusLabel(nextGymFocus)} 力量',
        subtitle: trainedYesterday
            ? '昨天已训练，今天避开 ${_gymFocusLabel(lastGymFocus)}，改做 ${_gymFocusLabel(nextGymFocus)} 主项，主动作 5 组以内。'
            : '建议选 1 个 ${_gymFocusLabel(nextGymFocus)} 主项动作 + 2 个辅助动作，本周保留一次拉伸放松。',
        intensity: '高',
        color: AppColors.gymAccent,
        icon: Icons.bolt,
      );
    case _TrainingGoalType.swimPerformance:
      return const _PlanSuggestion(
        title: '今天适合做一次专项游泳',
        subtitle: '如果精力正常，做技术分解 + 主训练组；如果状态一般，先做配速稳定练习。',
        intensity: '中',
        color: AppColors.swimAccent,
        icon: Icons.pool,
      );
    case _TrainingGoalType.consistency:
      return const _PlanSuggestion(
        title: '今天先完成最低剂量',
        subtitle: '哪怕只有 20 分钟，也先完成一节可执行的小训练，连续性比强度更重要。',
        intensity: '低门槛',
        color: Color(0xFF5B5BD6),
        icon: Icons.check_circle_outline,
      );
  }
}

List<_PlannedDay> _buildWeeklyPlan({
  required DateTime now,
  required _GoalConfig config,
  required List<WorkoutSession> sessions,
}) {
  final weekStart = _startOfWeek(now);
  final kinds = _buildAdaptiveWeekKinds(
    goal: config.goalType,
    trainingDays: config.trainingDaysPerWeek,
    sessions: sessions,
    weekStart: weekStart,
  );
  return List.generate(7, (index) {
    final date = weekStart.add(Duration(days: index));
    final kind = kinds[index];
    final completed = sessions.any(
      (session) =>
          session.date.year == date.year &&
          session.date.month == date.month &&
          session.date.day == date.day,
    );
    return _mapPlannedDay(date, kind, completed: completed);
  });
}

List<_PlanSessionKind> _goalTemplate(_TrainingGoalType goal) {
  return switch (goal) {
    _TrainingGoalType.fatLoss => [
        _PlanSessionKind.cardioSteady,
        _PlanSessionKind.gymFullBody,
        _PlanSessionKind.coreMobility,
        _PlanSessionKind.cardioIntervals,
        _PlanSessionKind.gymFullBody,
        _PlanSessionKind.cardioSteady,
        _PlanSessionKind.rest,
      ],
    _TrainingGoalType.muscleGain => [
        _PlanSessionKind.gymUpper,
        _PlanSessionKind.gymLower,
        _PlanSessionKind.recovery,
        _PlanSessionKind.gymPush,
        _PlanSessionKind.gymPull,
        _PlanSessionKind.gymFullBody,
        _PlanSessionKind.rest,
      ],
    _TrainingGoalType.endurance => [
        _PlanSessionKind.cardioSteady,
        _PlanSessionKind.coreMobility,
        _PlanSessionKind.cardioIntervals,
        _PlanSessionKind.recovery,
        _PlanSessionKind.cardioSteady,
        _PlanSessionKind.gymFullBody,
        _PlanSessionKind.rest,
      ],
    _TrainingGoalType.strength => [
        _PlanSessionKind.gymPush,
        _PlanSessionKind.gymPull,
        _PlanSessionKind.recovery,
        _PlanSessionKind.gymLower,
        _PlanSessionKind.coreMobility,
        _PlanSessionKind.gymFullBody,
        _PlanSessionKind.rest,
      ],
    _TrainingGoalType.swimPerformance => [
        _PlanSessionKind.swimTechnique,
        _PlanSessionKind.coreMobility,
        _PlanSessionKind.swimEndurance,
        _PlanSessionKind.recovery,
        _PlanSessionKind.swimTechnique,
        _PlanSessionKind.gymFullBody,
        _PlanSessionKind.rest,
      ],
    _TrainingGoalType.consistency => [
        _PlanSessionKind.gymFullBody,
        _PlanSessionKind.recovery,
        _PlanSessionKind.cardioSteady,
        _PlanSessionKind.rest,
        _PlanSessionKind.gymFullBody,
        _PlanSessionKind.coreMobility,
        _PlanSessionKind.rest,
      ],
  };
}

List<_PlanSessionKind> _buildAdaptiveWeekKinds({
  required _TrainingGoalType goal,
  required int trainingDays,
  required List<WorkoutSession> sessions,
  required DateTime weekStart,
}) {
  final template = _goalTemplate(goal).where((kind) => kind != _PlanSessionKind.rest).toList();
  final targetDays = trainingDays.clamp(2, 6);
  final weekDates = List.generate(7, (index) => weekStart.add(Duration(days: index)));
  final completedThisWeek = weekDates
      .where((date) => sessions.any((session) => _isSameDay(session.date, date)))
      .length;

  final priorTrainingStreak = _trainingStreakBeforeDate(sessions, weekStart);
  final kinds = <_PlanSessionKind>[];
  var templateIndex = 0;
  var scheduledTrainings = 0;
  var rollingStreak = priorTrainingStreak;

  for (var i = 0; i < weekDates.length; i++) {
    final remainingDays = weekDates.length - i;
    final remainingTrainings = (targetDays - scheduledTrainings).clamp(0, remainingDays);
    final mustTrainToday = remainingTrainings == remainingDays;

    if (scheduledTrainings >= targetDays) {
      kinds.add(_PlanSessionKind.rest);
      rollingStreak = 0;
      continue;
    }

    final shouldRecover = rollingStreak >= 3 && !mustTrainToday;
    if (shouldRecover) {
      kinds.add(_PlanSessionKind.recovery);
      rollingStreak = 0;
      continue;
    }

    final kind = template[templateIndex % template.length];
    kinds.add(kind);
    templateIndex++;
    scheduledTrainings++;
    rollingStreak++;
  }

  final needsRecovery = targetDays >= 3 && !kinds.contains(_PlanSessionKind.recovery);
  if (needsRecovery) {
    final restIndex = kinds.lastIndexOf(_PlanSessionKind.rest);
    if (restIndex != -1) {
      kinds[restIndex] = _PlanSessionKind.recovery;
    }
  }

  if (completedThisWeek >= targetDays) {
    return kinds
        .asMap()
        .entries
        .map((entry) => entry.key == 0 ? entry.value : _downgradeFutureLoad(entry.value))
        .toList();
  }

  return kinds;
}

_PlanSessionKind _downgradeFutureLoad(_PlanSessionKind kind) {
  switch (kind) {
    case _PlanSessionKind.recovery:
    case _PlanSessionKind.rest:
      return kind;
    default:
      return _PlanSessionKind.recovery;
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

int _trainingStreakBeforeDate(List<WorkoutSession> sessions, DateTime date) {
  var streak = 0;
  var cursor = date.subtract(const Duration(days: 1));
  while (sessions.any((session) => _isSameDay(session.date, cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

_PlanSessionKind _lastGymFocus(List<WorkoutSession> sessions) {
  for (final session in sessions) {
    if (session.type != WorkoutType.gym) continue;
    return _focusFromSession(session) ?? _PlanSessionKind.gymFullBody;
  }
  return _PlanSessionKind.gymFullBody;
}

_PlanSessionKind _nextGymFocus(List<WorkoutSession> sessions, _TrainingGoalType goal) {
  final cycle = _gymFocusCycle(goal);
  final recentFocuses = sessions
      .where((session) => session.type == WorkoutType.gym)
      .map((session) => _focusFromSession(session))
      .whereType<_PlanSessionKind>()
      .take(4)
      .toList();

  for (final focus in cycle) {
    if (!recentFocuses.contains(focus)) {
      return focus;
    }
  }

  final last = recentFocuses.isEmpty ? cycle.first : recentFocuses.first;
  final index = cycle.indexOf(last);
  if (index == -1) return cycle.first;
  return cycle[(index + 1) % cycle.length];
}

List<_PlanSessionKind> _gymFocusCycle(_TrainingGoalType goal) {
  switch (goal) {
    case _TrainingGoalType.muscleGain:
      return const [
        _PlanSessionKind.gymPull,
        _PlanSessionKind.gymLower,
        _PlanSessionKind.gymUpper,
      ];
    case _TrainingGoalType.strength:
      return const [
        _PlanSessionKind.gymPull,
        _PlanSessionKind.gymLower,
        _PlanSessionKind.gymUpper,
      ];
    default:
      return const [
        _PlanSessionKind.gymPull,
        _PlanSessionKind.gymLower,
        _PlanSessionKind.gymUpper,
      ];
  }
}

_PlanSessionKind? _focusFromSession(WorkoutSession session) {
  if (session.type != WorkoutType.gym) return null;
  final exercises = session.exercises;
  if (exercises == null || exercises.isEmpty) return _PlanSessionKind.gymFullBody;

  final counts = <MuscleGroup, int>{};
  for (final exercise in exercises) {
    counts[exercise.muscleGroup] = (counts[exercise.muscleGroup] ?? 0) + 1;
  }
  final ordered = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topGroups = ordered.take(2).map((entry) => entry.key).toSet();

  final hasChestShoulderArm = topGroups.any((group) => {
        MuscleGroup.chest,
        MuscleGroup.shoulders,
        MuscleGroup.arms,
      }.contains(group));
  final hasBack = topGroups.contains(MuscleGroup.back);
  final isLower = topGroups.contains(MuscleGroup.glutesAndLegs);
  final isCore = topGroups.contains(MuscleGroup.core);

  if (isLower && (hasChestShoulderArm || hasBack || isCore)) {
    return _PlanSessionKind.gymFullBody;
  }
  if (isLower) return _PlanSessionKind.gymLower;
  if (hasBack && !hasChestShoulderArm) return _PlanSessionKind.gymPull;
  if (hasChestShoulderArm || isCore) return _PlanSessionKind.gymUpper;
  return _PlanSessionKind.gymFullBody;
}

String _gymFocusLabel(_PlanSessionKind kind) {
  switch (kind) {
    case _PlanSessionKind.gymUpper:
      return '胸肩手臂';
    case _PlanSessionKind.gymLower:
      return '臀腿';
    case _PlanSessionKind.gymPull:
      return '背部';
    case _PlanSessionKind.gymPush:
      return '胸肩手臂';
    case _PlanSessionKind.gymFullBody:
      return '全身';
    case _PlanSessionKind.coreMobility:
      return '拉伸放松';
    default:
      return '不同肌群';
  }
}

_PlannedDay _mapPlannedDay(
  DateTime date,
  _PlanSessionKind kind, {
  required bool completed,
}) {
  final weekday = DateFormat('E', 'zh_CN').format(date);
  final suffix = completed ? ' 已完成' : '';
  switch (kind) {
    case _PlanSessionKind.gymUpper:
      return _PlannedDay(
        date: date,
        kind: kind,
        title: '$weekday 胸肩手臂$suffix',
        detail: '卧推或推举做主项，再补侧平举、臂屈伸或弯举，控制总量别堆太杂。',
        durationLabel: '50-65 分钟',
        color: AppColors.gymAccent,
        icon: Icons.fitness_center,
      );
    case _PlanSessionKind.gymLower:
      return _PlannedDay(
        date: date,
        kind: kind,
        title: '$weekday 臀腿训练$suffix',
        detail: '深蹲、臀桥、罗马尼亚硬拉或腿举里选 1 到 2 个主项，再补腿后侧。',
        durationLabel: '55-70 分钟',
        color: AppColors.gymAccent,
        icon: Icons.sports_gymnastics,
      );
    case _PlanSessionKind.gymPush:
      return _PlannedDay(
        date: date,
        kind: kind,
        title: '$weekday 胸肩手臂$suffix',
        detail: '胸、肩、手臂为主，动作数量适中，保证主项质量。',
        durationLabel: '45-60 分钟',
        color: AppColors.gymAccent,
        icon: Icons.arrow_upward,
      );
    case _PlanSessionKind.gymPull:
      return _PlannedDay(
        date: date,
        kind: kind,
        title: '$weekday 背部训练$suffix',
        detail: '下拉、划船、后束和少量二头，重点放在背部发力和动作控制。',
        durationLabel: '45-60 分钟',
        color: AppColors.gymAccent,
        icon: Icons.arrow_downward,
      );
    case _PlanSessionKind.gymFullBody:
      return _PlannedDay(
        date: date,
        kind: kind,
        title: '$weekday 全身训练$suffix',
        detail: '选择 1 个下肢主项、1 个推、1 个拉，再加核心。',
        durationLabel: '40-55 分钟',
        color: AppColors.gymAccent,
        icon: Icons.accessibility_new,
      );
    case _PlanSessionKind.coreMobility:
      return _PlannedDay(
        date: date,
        kind: kind,
        title: '$weekday 拉伸放松$suffix',
        detail: '做胸椎、髋、腘绳肌和肩部拉伸，配合泡沫轴或轻松步行，帮助恢复。',
        durationLabel: '20-30 分钟',
        color: const Color(0xFF8E8EF8),
        icon: Icons.self_improvement,
      );
    case _PlanSessionKind.cardioSteady:
      return _PlannedDay(
        date: date,
        kind: kind,
        title: '$weekday 稳态有氧$suffix',
        detail: '快走、慢跑或骑行，心率保持在可以完整说话的区间。',
        durationLabel: '35-55 分钟',
        color: AppColors.cardioAccent,
        icon: Icons.monitor_heart_outlined,
      );
    case _PlanSessionKind.cardioIntervals:
      return _PlannedDay(
        date: date,
        kind: kind,
        title: '$weekday 间歇课$suffix',
        detail: '热身后做 4 到 6 组 1:1 间歇，结束做 10 分钟冷身。',
        durationLabel: '30-40 分钟',
        color: AppColors.cardioAccent,
        icon: Icons.speed,
      );
    case _PlanSessionKind.swimTechnique:
      return _PlannedDay(
        date: date,
        kind: kind,
        title: '$weekday 游泳技术课$suffix',
        detail: '先做打腿、划手和配合练习，再做短距离技术巩固。',
        durationLabel: '35-50 分钟',
        color: AppColors.swimAccent,
        icon: Icons.pool,
      );
    case _PlanSessionKind.swimEndurance:
      return _PlannedDay(
        date: date,
        kind: kind,
        title: '$weekday 游泳耐力课$suffix',
        detail: '主训练组做中长距离分段，重点把配速拉稳。',
        durationLabel: '40-60 分钟',
        color: AppColors.swimAccent,
        icon: Icons.water,
      );
    case _PlanSessionKind.recovery:
      return _PlannedDay(
        date: date,
        kind: kind,
        title: '$weekday 主动恢复$suffix',
        detail: '轻松步行、拉伸或泡沫轴，目标是恢复而不是加练。',
        durationLabel: '15-25 分钟',
        color: const Color(0xFF34C759),
        icon: Icons.favorite_outline,
      );
    case _PlanSessionKind.rest:
      return _PlannedDay(
        date: date,
        kind: kind,
        title: '$weekday 休息日$suffix',
        detail: '完全休息也算计划的一部分，避免把疲劳累积到下一节。',
        durationLabel: '0 分钟',
        color: const Color(0xFFB0B7C3),
        icon: Icons.hotel_outlined,
      );
  }
}

List<_ActionItem> _buildActionItems({
  required _GoalConfig config,
  required BodyMetrics? metrics,
  required List<WorkoutSession> weeklySessions,
  required List<WorkoutSession> monthlySessions,
  required WorkoutProvider workoutProvider,
}) {
  final items = <_ActionItem>[];
  final gymCount = weeklySessions.where((item) => item.type == WorkoutType.gym).length;
  final cardioCount =
      weeklySessions.where((item) => item.type == WorkoutType.cardio).length;
  final swimCount = weeklySessions.where((item) => item.type == WorkoutType.swim).length;

  if (weeklySessions.length < config.trainingDaysPerWeek) {
    items.add(
      _ActionItem(
        title: '先补齐本周频率',
        subtitle:
            '本周已完成 ${weeklySessions.length}/${config.trainingDaysPerWeek} 天。优先保证频率，再追求强度和内容完整。',
        color: const Color(0xFF5B5BD6),
        icon: Icons.event_repeat,
      ),
    );
  }

  switch (config.goalType) {
    case _TrainingGoalType.fatLoss:
      items.add(
        _ActionItem(
          title: '保持力量训练不掉线',
          subtitle: gymCount == 0
              ? '减脂期仍建议每周至少 2 次力量训练，避免只做有氧。'
              : '目前力量课已开张，继续把大动作留在周计划里。',
          color: AppColors.gymAccent,
          icon: Icons.fitness_center,
        ),
      );
      if (metrics?.bodyFatPercentage == null) {
        items.add(
          const _ActionItem(
            title: '补一条体脂记录',
            subtitle: '减脂目标只看体重容易失真，建议同步记录体脂率或腰围。',
            color: Color(0xFF00A3FF),
            icon: Icons.monitor_weight_outlined,
          ),
        );
      }
      break;
    case _TrainingGoalType.muscleGain:
      items.add(
        _ActionItem(
          title: '把每周力量课稳定在高优先级',
          subtitle: gymCount >= 3
              ? '当前频率够用，下一步是保证主动作组数和恢复。'
              : '本周力量训练偏少，增肌阶段先把每周 3 次左右做稳。',
          color: AppColors.gymAccent,
          icon: Icons.trending_up,
        ),
      );
      if (metrics?.muscleMass == null) {
        items.add(
          const _ActionItem(
            title: '记录肌肉量或围度',
            subtitle: '没有体成分记录时，很难区分体重上涨是增肌还是水分波动。',
            color: Color(0xFF8E8EF8),
            icon: Icons.straighten,
          ),
        );
      }
      break;
    case _TrainingGoalType.endurance:
      final distanceKm = monthlySessions.fold<double>(
        0,
        (sum, session) => sum + ((session.totalDistanceMeters ?? 0) / 1000),
      );
      items.add(
        _ActionItem(
          title: '优先累积低强度总量',
          subtitle: '本月累计 ${distanceKm.toStringAsFixed(1)} km。耐力目标先做总量，再插入少量间歇。',
          color: AppColors.cardioAccent,
          icon: Icons.route,
        ),
      );
      if (cardioCount + swimCount < 2) {
        items.add(
          const _ActionItem(
            title: '有氧频次还不够',
            subtitle: '每周至少安排 2 次持续心肺训练，否则很难稳定提升耐力底盘。',
            color: Color(0xFF00B894),
            icon: Icons.directions_run,
          ),
        );
      }
      break;
    case _TrainingGoalType.strength:
      items.add(
        _ActionItem(
          title: '减少无计划的杂项动作',
          subtitle: '力量目标下，优先做主项和固定辅助动作，别把体能课挤占掉恢复。',
          color: AppColors.gymAccent,
          icon: Icons.bolt,
        ),
      );
      items.add(
        _ActionItem(
          title: '追踪主项表现',
          subtitle: '下次训练至少记录一个主项的重量、次数或组数变化，避免只记“练过了”。',
          color: const Color(0xFF8E8EF8),
          icon: Icons.bar_chart,
        ),
      );
      break;
    case _TrainingGoalType.swimPerformance:
      final swimDistanceKm = monthlySessions
          .where((item) => item.type == WorkoutType.swim)
          .fold<double>(
            0,
            (sum, session) => sum + ((session.totalDistanceMeters ?? 0) / 1000),
          );
      items.add(
        _ActionItem(
          title: '保留技术课和主训练组',
          subtitle: '本月游泳 ${swimDistanceKm.toStringAsFixed(1)} km。专项目标下，不要每次都游成同一配速。',
          color: AppColors.swimAccent,
          icon: Icons.pool,
        ),
      );
      if (swimCount == 0) {
        items.add(
          const _ActionItem(
            title: '本周还没有下水',
            subtitle: '游泳专项至少要有 2 次水中训练，陆上训练只能作为辅助。',
            color: Color(0xFF00A3FF),
            icon: Icons.water,
          ),
        );
      }
      break;
    case _TrainingGoalType.consistency:
      items.add(
        _ActionItem(
          title: '把门槛降到能天天开始',
          subtitle: '当前连续 ${workoutProvider.currentStreak} 天。连续性阶段不追求完美，先追求不间断。',
          color: const Color(0xFF5B5BD6),
          icon: Icons.check_circle_outline,
        ),
      );
      items.add(
        const _ActionItem(
          title: '预留一个 20 分钟备选方案',
          subtitle: '当天太忙时，直接执行备选短课，别因为完整计划做不了就整天空过。',
          color: Color(0xFF34C759),
          icon: Icons.timer_outlined,
        ),
      );
      break;
  }

  return items.take(3).toList();
}

String _goalLabel(_TrainingGoalType goal) {
  switch (goal) {
    case _TrainingGoalType.fatLoss:
      return '减脂';
    case _TrainingGoalType.muscleGain:
      return '增肌';
    case _TrainingGoalType.endurance:
      return '提升耐力';
    case _TrainingGoalType.strength:
      return '提升力量';
    case _TrainingGoalType.swimPerformance:
      return '游泳专项';
    case _TrainingGoalType.consistency:
      return '养成习惯';
  }
}

class _HeroCard extends StatelessWidget {
  final _GoalConfig config;
  final int weeklySessions;
  final int streak;
  final VoidCallback onEdit;

  const _HeroCard({
    required this.config,
    required this.weeklySessions,
    required this.streak,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.track_changes, color: Colors.white),
              ),
              const Spacer(),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                ),
                child: const Text('调整目标'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _goalLabel(config.goalType),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '让计划围着目标转',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '本周已完成 $weeklySessions/${config.trainingDaysPerWeek} 天训练，当前连续打卡 $streak 天。',
            style: const TextStyle(
              color: Colors.white,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF172033),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
              ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final _GoalProgress progress;

  const _ProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            progress.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  label: '当前',
                  value: progress.currentLabel,
                  color: const Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricPill(
                  label: '目标',
                  value: progress.targetLabel,
                  color: const Color(0xFF0EA5E9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress.ratio,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '完成度 ${(progress.ratio * 100).round()}%',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF4F46E5),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF172033),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final _PlanSuggestion suggestion;

  const _SuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: suggestion.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(suggestion.icon, color: suggestion.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        suggestion.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF172033),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: suggestion.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        suggestion.intensity,
                        style: TextStyle(
                          color: suggestion.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  suggestion.subtitle,
                  style: const TextStyle(
                    height: 1.5,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannedDayCard extends StatelessWidget {
  final _PlannedDay day;

  const _PlannedDayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('M月d日', 'zh_CN').format(day.date);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: day.color.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: day.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(day.icon, color: day.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        day.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF172033),
                        ),
                      ),
                    ),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  day.detail,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  day.durationLabel,
                  style: TextStyle(
                    color: day.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final _ActionItem item;

  const _ActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalEditorFields extends StatelessWidget {
  final _TrainingGoalType selectedGoal;
  final TextEditingController weightController;
  final TextEditingController bodyFatController;
  final TextEditingController muscleController;
  final TextEditingController distanceController;
  final TextEditingController streakController;

  const _GoalEditorFields({
    required this.selectedGoal,
    required this.weightController,
    required this.bodyFatController,
    required this.muscleController,
    required this.distanceController,
    required this.streakController,
  });

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[];
    if (selectedGoal == _TrainingGoalType.fatLoss) {
      fields.add(_EditorInput(
        label: '目标体重 (kg)',
        controller: weightController,
        hint: '例如 60',
      ));
      fields.add(_EditorInput(
        label: '目标体脂率 (%)',
        controller: bodyFatController,
        hint: '可选，例如 18',
      ));
    } else if (selectedGoal == _TrainingGoalType.muscleGain) {
      fields.add(_EditorInput(
        label: '目标肌肉量 (kg)',
        controller: muscleController,
        hint: '例如 28',
      ));
    } else if (selectedGoal == _TrainingGoalType.endurance ||
        selectedGoal == _TrainingGoalType.swimPerformance) {
      fields.add(_EditorInput(
        label: selectedGoal == _TrainingGoalType.swimPerformance
            ? '月游泳目标距离 (km)'
            : '月耐力目标距离 (km)',
        controller: distanceController,
        hint: '例如 30',
      ));
    } else if (selectedGoal == _TrainingGoalType.consistency) {
      fields.add(_EditorInput(
        label: '连续打卡目标 (天)',
        controller: streakController,
        hint: '例如 21',
      ));
    }
    if (fields.isEmpty) {
      fields.add(
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            '当前目标不需要额外数值，保存后会按训练频率生成计划。',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
      );
    }
    return Column(children: fields);
  }
}

class _EditorInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  const _EditorInput({
    required this.label,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF7F8FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
