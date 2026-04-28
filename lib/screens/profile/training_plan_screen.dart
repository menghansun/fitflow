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
  swimPerformance,
  consistency,
}

_TrainingGoalType _parseTrainingGoalType(String? name) {
  switch (name) {
    case 'fatLoss':
      return _TrainingGoalType.fatLoss;
    case 'muscleGain':
      return _TrainingGoalType.muscleGain;
    case 'swimPerformance':
      return _TrainingGoalType.swimPerformance;
    case 'consistency':
      return _TrainingGoalType.consistency;
    // Legacy keys (older app versions had 6 goal types).
    case 'endurance':
      return _TrainingGoalType.fatLoss;
    case 'strength':
      return _TrainingGoalType.muscleGain;
    default:
      return _TrainingGoalType.consistency;
  }
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
      goalType: _parseTrainingGoalType(goalTypeName),
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

class _WeeklyDirectionProgress {
  final String focusTitle;
  final String focusSubtitle;
  final int strengthDone;
  final int strengthTarget;
  final int swimCardioDone;
  final int swimCardioTarget;
  final int recoveryDone;
  final int recoveryTarget;
  final double overallRatio;
  final String nextStep;

  const _WeeklyDirectionProgress({
    required this.focusTitle,
    required this.focusSubtitle,
    required this.strengthDone,
    required this.strengthTarget,
    required this.swimCardioDone,
    required this.swimCardioTarget,
    required this.recoveryDone,
    required this.recoveryTarget,
    required this.overallRatio,
    required this.nextStep,
  });
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
        final weeklyDirection = _buildWeeklyDirectionProgress(
          config: _config,
          sessions: sessions,
          weekStart: weekStart,
          now: now,
        );
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
          now: now,
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
                const _SectionTitle(
                  title: '本周训练方向',
                  subtitle: '按计划类型统计每周目标和完成进度',
                ),
                const SizedBox(height: 12),
                _WeeklyDirectionCard(progress: weeklyDirection),
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
                  subtitle: '与本周安排一致，并结合今天 / 昨天是否已训练',
                ),
                const SizedBox(height: 12),
                _SuggestionCard(suggestion: suggestion),
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
                        children: [
                          _TrainingGoalType.fatLoss,
                          _TrainingGoalType.muscleGain,
                          _TrainingGoalType.swimPerformance,
                          _TrainingGoalType.consistency,
                        ].map((goal) {
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

_WeeklyDirectionProgress _buildWeeklyDirectionProgress({
  required _GoalConfig config,
  required List<WorkoutSession> sessions,
  required DateTime weekStart,
  required DateTime now,
}) {
  // 根据目标类型确定每周目标次数
  final targets = _getWeeklyTargets(config);
  final strengthTarget = targets['strength']!;
  final swimCardioTarget = targets['swimCardio']!;
  final recoveryTarget = targets['recovery']!;

  // 统计本周已完成次数
  final weekDates = List.generate(7, (index) => weekStart.add(Duration(days: index)));
  var strengthDone = 0;
  var swimCardioDone = 0;
  var recoveryDone = 0;

  for (final date in weekDates) {
    final daySessions = sessions.where((s) => _isSameDay(s.date, date)).toList();
    for (final session in daySessions) {
      switch (session.type) {
        case WorkoutType.gym:
          strengthDone++;
          break;
        case WorkoutType.swim:
        case WorkoutType.cardio:
          swimCardioDone++;
          break;
        default:
          break;
      }
    }
  }

  final totalTarget = strengthTarget + swimCardioTarget + recoveryTarget;
  final totalDone = strengthDone + swimCardioDone + recoveryDone;
  final overallRatio =
      totalTarget == 0 ? 0.0 : (totalDone / totalTarget).clamp(0.0, 1.0);

  final focusTitle = switch (config.goalType) {
    _TrainingGoalType.fatLoss => '本周重点：燃脂 + 保肌肉',
    _TrainingGoalType.muscleGain => '本周重点：力量训练为主',
    _TrainingGoalType.swimPerformance => '本周重点：游泳专项推进',
    _TrainingGoalType.consistency => '本周重点：先稳定连续性',
  };
  final focusSubtitle = switch (config.goalType) {
    _TrainingGoalType.fatLoss => '2 天力量 + 2 天游泳/有氧，保证消耗同时保住肌肉量。',
    _TrainingGoalType.muscleGain => '至少 3 天力量训练，游泳/有氧用于补充心肺与恢复。',
    _TrainingGoalType.swimPerformance => '优先完成技术课和耐力课，陆上训练做辅助。',
    _TrainingGoalType.consistency => '按计划把训练做完，比追求强度更重要。',
  };

  final nextStep = switch (true) {
    _ when strengthDone < strengthTarget =>
      '下一步：本周还差 ${strengthTarget - strengthDone} 次力量训练。',
    _ when swimCardioDone < swimCardioTarget =>
      '下一步：本周还差 ${swimCardioTarget - swimCardioDone} 次游泳/有氧。',
    _ when recoveryDone < recoveryTarget =>
      '下一步：预留 ${recoveryTarget - recoveryDone} 次拉伸或休息，保证恢复。',
    _ => '下一步：本周目标已完成，按状态保持即可。',
  };

  return _WeeklyDirectionProgress(
    focusTitle: focusTitle,
    focusSubtitle: focusSubtitle,
    strengthDone: strengthDone,
    strengthTarget: strengthTarget,
    swimCardioDone: swimCardioDone,
    swimCardioTarget: swimCardioTarget,
    recoveryDone: recoveryDone,
    recoveryTarget: recoveryTarget,
    overallRatio: overallRatio,
    nextStep: nextStep,
  );
}

Map<String, int> _getWeeklyTargets(_GoalConfig config) {
  // 返回 Map: 'strength', 'swimCardio', 'recovery'
  switch (config.goalType) {
    case _TrainingGoalType.fatLoss:
      return {'strength': 2, 'swimCardio': 2, 'recovery': 0};
    case _TrainingGoalType.muscleGain:
      return {'strength': 3, 'swimCardio': 1, 'recovery': 1};
    case _TrainingGoalType.swimPerformance:
      return {'strength': 1, 'swimCardio': 4, 'recovery': 0};
    case _TrainingGoalType.consistency:
      return {'strength': 2, 'swimCardio': 2, 'recovery': 1};
  }
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
        final baseline =
            (currentWeight > targetWeight ? currentWeight : targetWeight) + 3;
        final ratio =
            ((baseline - currentWeight) / (baseline - targetWeight)).clamp(0.0, 1.0);
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
        final ratio =
            ((currentMuscle - baseline) / (targetMuscle - baseline)).clamp(0.0, 1.0);
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
    case _TrainingGoalType.swimPerformance:
      final swimDistanceKm = monthlySessions
          .where((s) => s.type == WorkoutType.swim)
          .fold<double>(
            0,
            (sum, session) => sum + ((session.totalDistanceMeters ?? 0) / 1000),
          );
      final targetKm = config.targetMonthlyDistanceKm ?? 20;
      return _GoalProgress(
        title: '月游泳距离目标',
        currentLabel: '${swimDistanceKm.toStringAsFixed(1)} km',
        targetLabel: '${targetKm.toStringAsFixed(0)} km',
        ratio: (swimDistanceKm / targetKm).clamp(0.0, 1.0),
        hint: '按本月游泳累计距离跟踪；可与周计划中的技术课、耐力课配合。',
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
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final todaySessions = sessions.where((s) => _isSameDay(s.date, today)).toList();
  final trainedToday = todaySessions.isNotEmpty;

  final targets = _getWeeklyTargets(config);
  final strengthDone = weeklySessions.where((s) => s.type == WorkoutType.gym).length;
  final swimCardioDone = weeklySessions
      .where((s) => s.type == WorkoutType.swim || s.type == WorkoutType.cardio)
      .length;

  final strengthRemaining = (targets['strength']! - strengthDone).clamp(0, 999);
  final swimCardioRemaining = (targets['swimCardio']! - swimCardioDone).clamp(0, 999);

  if (trainedToday) {
    return const _PlanSuggestion(
      title: '今天以恢复为主',
      subtitle: '你今天已经完成训练，优先补水、拉伸 10 分钟，避免重复加量。',
      intensity: '恢复',
      color: Color(0xFF34C759),
      icon: Icons.self_improvement,
    );
  }

  // 根据目标类型决定推荐逻辑
  return _getTodaySuggestionByGoal(
    config.goalType,
    strengthRemaining,
    swimCardioRemaining,
    sessions,
    now,
  );
}

_PlanSuggestion _getTodaySuggestionByGoal(
  _TrainingGoalType goalType,
  int strengthRemaining,
  int swimCardioRemaining,
  List<WorkoutSession> sessions,
  DateTime now,
) {
  switch (goalType) {
    case _TrainingGoalType.fatLoss:
      // 减脂：2力量 + 2游泳，按缺口比例推荐
      if (strengthRemaining > 0 && swimCardioRemaining > 0) {
        // 两者都缺，看缺口大小
        final strengthRatio = strengthRemaining / 2;
        final swimRatio = swimCardioRemaining / 2;
        if (strengthRatio >= swimRatio) {
          return _buildMuscleSuggestion(sessions, now, '减脂');
        } else {
          return const _PlanSuggestion(
            title: '今天适合游泳/有氧',
            subtitle: '减脂需要一定有氧消耗，游泳或慢跑都是很好的选择。',
            intensity: '中',
            color: Color(0xFF00A3FF),
            icon: Icons.pool,
          );
        }
      } else if (strengthRemaining > 0) {
        return _buildMuscleSuggestion(sessions, now, '减脂');
      } else if (swimCardioRemaining > 0) {
        return const _PlanSuggestion(
          title: '今天适合游泳/有氧',
          subtitle: '本周游泳/有氧目标还没完成，去泳池或户外动一动。',
          intensity: '中',
          color: Color(0xFF00A3FF),
          icon: Icons.pool,
        );
      } else {
        return const _PlanSuggestion(
          title: '本周目标已完成',
          subtitle: '可以轻松散步、拉伸放松，或完全休息。',
          intensity: '低',
          color: Color(0xFF34C759),
          icon: Icons.celebration_outlined,
        );
      }

    case _TrainingGoalType.muscleGain:
      // 增肌：3力量 + 1游泳，力量为主
      if (strengthRemaining > 0) {
        return _buildMuscleSuggestion(sessions, now, '增肌');
      } else if (swimCardioRemaining > 0) {
        return const _PlanSuggestion(
          title: '今天适合游泳/有氧',
          subtitle: '力量目标已完成，可以去泳池放松一下，辅助恢复。',
          intensity: '中',
          color: Color(0xFF00A3FF),
          icon: Icons.pool,
        );
      } else {
        return const _PlanSuggestion(
          title: '本周目标已完成',
          subtitle: '可以轻松散步、拉伸放松，或完全休息。',
          intensity: '低',
          color: Color(0xFF34C759),
          icon: Icons.celebration_outlined,
        );
      }

    case _TrainingGoalType.swimPerformance:
      // 游泳：1力量 + 4游泳，游泳为主
      if (swimCardioRemaining > 0) {
        return const _PlanSuggestion(
          title: '今天适合游泳',
          subtitle: '游泳专项需要保持水中感觉，去泳池练一练。',
          intensity: '中',
          color: Color(0xFF00A3FF),
          icon: Icons.pool,
        );
      } else if (strengthRemaining > 0) {
        return _buildMuscleSuggestion(sessions, now, '游泳');
      } else {
        return const _PlanSuggestion(
          title: '本周游泳目标已完成',
          subtitle: '可以轻松散步、拉伸放松，或完全休息。',
          intensity: '低',
          color: Color(0xFF34C759),
          icon: Icons.celebration_outlined,
        );
      }

    case _TrainingGoalType.consistency:
      // 养成习惯：2力量 + 2游泳，看缺口比例
      if (strengthRemaining > 0 && swimCardioRemaining > 0) {
        final strengthRatio = strengthRemaining / 2;
        final swimRatio = swimCardioRemaining / 2;
        if (strengthRatio >= swimRatio) {
          return _buildMuscleSuggestion(sessions, now, '养成习惯');
        } else {
          return const _PlanSuggestion(
            title: '今天适合游泳/有氧',
            subtitle: '保持多样化的运动习惯对健康很重要。',
            intensity: '中',
            color: Color(0xFF00A3FF),
            icon: Icons.pool,
          );
        }
      } else if (strengthRemaining > 0) {
        return _buildMuscleSuggestion(sessions, now, '养成习惯');
      } else if (swimCardioRemaining > 0) {
        return const _PlanSuggestion(
          title: '今天适合游泳/有氧',
          subtitle: '本周游泳/有氧目标还没完成，去泳池或户外动一动。',
          intensity: '中',
          color: Color(0xFF00A3FF),
          icon: Icons.pool,
        );
      } else {
        return const _PlanSuggestion(
          title: '本周目标已完成',
          subtitle: '可以轻松散步、拉伸放松，或完全休息。',
          intensity: '低',
          color: Color(0xFF34C759),
          icon: Icons.celebration_outlined,
        );
      }
  }
}

_PlanSuggestion _buildMuscleSuggestion(
  List<WorkoutSession> sessions,
  DateTime now,
  String goalType,
) {
  final suggestion = _getMuscleGroupSuggestion(sessions, now);
  return _PlanSuggestion(
    title: '今天适合练${suggestion.name}',
    subtitle: suggestion.hint,
    intensity: '高',
    color: const Color(0xFFFF6B6B),
    icon: Icons.fitness_center,
  );
}

_MuscleSuggestion _getMuscleGroupSuggestion(List<WorkoutSession> sessions, DateTime now) {
  final recentGymSessions = sessions
      .where((s) => s.type == WorkoutType.gym && s.exercises != null)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  final muscleGroupDays = <MuscleGroup, int>{};
  for (final session in recentGymSessions) {
    final daysAgo = now.difference(session.date).inDays;
    if (daysAgo > 7) break;
    for (final exercise in session.exercises!) {
      muscleGroupDays[exercise.muscleGroup] = daysAgo;
    }
  }

  MuscleGroup? leastTrained;
  int maxDays = 0;
  for (final entry in muscleGroupDays.entries) {
    if (entry.value > maxDays) {
      maxDays = entry.value;
      leastTrained = entry.key;
    }
  }

  switch (leastTrained) {
    case MuscleGroup.chest:
    case MuscleGroup.shoulders:
    case MuscleGroup.arms:
      return const _MuscleSuggestion(
        name: '上肢推（胸肩手臂）',
        hint: '胸部、肩部、手臂有一段时间没练了，今天推类训练很合适。',
      );
    case MuscleGroup.back:
      return const _MuscleSuggestion(
        name: '背部',
        hint: '背部肌肉最近没怎么练，拉类训练可以帮助改善体态。',
      );
    case MuscleGroup.glutesAndLegs:
      return const _MuscleSuggestion(
        name: '臀腿',
        hint: '臀腿是人体最大的肌群，训练收益很高，今天很适合练。',
      );
    default:
      return const _MuscleSuggestion(
        name: '背部',
        hint: '今天推荐练背部，帮助改善体态和提升力量。',
      );
  }
}

class _MuscleSuggestion {
  final String name;
  final String hint;
  const _MuscleSuggestion({required this.name, required this.hint});
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
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
          subtitle: gymCount >= 3
              ? '减脂保肌阶段的 3 天力量已达标，继续把动作质量放在第一位。'
              : '当前力量课不足 3 天，建议补齐胸肩手臂 / 背部 / 臀腿三次力量日。',
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
    case _TrainingGoalType.swimPerformance:
      return '游泳';
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

class _WeeklyDirectionCard extends StatelessWidget {
  final _WeeklyDirectionProgress progress;

  const _WeeklyDirectionCard({required this.progress});

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
            progress.focusTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            progress.focusSubtitle,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          _DirectionProgressRow(
            label: '力量',
            done: progress.strengthDone,
            target: progress.strengthTarget,
          ),
          const SizedBox(height: 10),
          _DirectionProgressRow(
            label: '游泳/有氧',
            done: progress.swimCardioDone,
            target: progress.swimCardioTarget,
          ),
          const SizedBox(height: 10),
          _DirectionProgressRow(
            label: '拉伸休息',
            done: progress.recoveryDone,
            target: progress.recoveryTarget,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              progress.nextStep,
              style: const TextStyle(
                color: Color(0xFF4A5A8A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionProgressRow extends StatelessWidget {
  final String label;
  final int done;
  final int target;

  const _DirectionProgressRow({
    required this.label,
    required this.done,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = target <= 0 ? 0.0 : (done / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$done/$target',
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: ratio,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
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
    } else if (selectedGoal == _TrainingGoalType.swimPerformance) {
      fields.add(_EditorInput(
        label: '月游泳目标距离 (km)',
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
