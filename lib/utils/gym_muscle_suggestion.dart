import '../models/workout_session.dart';

/// Text recommendation for home / training plan "today" muscle hints.
class GymMuscleSuggestion {
  final String name;
  final String hint;
  const GymMuscleSuggestion({required this.name, required this.hint});
}

/// Picks a muscle focus based on recent gym logs.
///
/// - Computes calendar days since each [MuscleGroup] was last trained (full history).
/// - Skips groups trained **yesterday or today** (`daysSince <= 1`) so we do not repeat
///   the same area right after a session.
/// - Among the rest, prefers the longest time since last work (needs attention most).
/// - If every group was hit within the last day (edge case), returns a recovery-style hint.
GymMuscleSuggestion computeGymMuscleSuggestion(List<WorkoutSession> sessions, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);

  final daysSinceLast = <MuscleGroup, int>{
    for (final g in MuscleGroup.values) g: 999,
  };

  final gymSessions = sessions
      .where(
        (s) =>
            s.type == WorkoutType.gym &&
            s.exercises != null &&
            s.exercises!.isNotEmpty &&
            s.countsAsWorkout,
      )
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  for (final session in gymSessions) {
    final sessionDay = DateTime(session.date.year, session.date.month, session.date.day);
    final daysAgo = today.difference(sessionDay).inDays;
    if (daysAgo < 0) continue;
    for (final ex in session.exercises!) {
      final g = ex.muscleGroup;
      if (daysSinceLast[g] == 999) {
        daysSinceLast[g] = daysAgo;
      }
    }
  }

  // Do not suggest a muscle trained within the last full calendar day (yesterday/today).
  const recentThreshold = 1;
  MuscleGroup? best;
  var bestDays = -1;
  for (final g in MuscleGroup.values) {
    final d = daysSinceLast[g]!;
    if (d <= recentThreshold) continue;
    if (d > bestDays) {
      bestDays = d;
      best = g;
    }
  }

  if (best == null) {
    return const GymMuscleSuggestion(
      name: '轻度有氧或拉伸',
      hint: '力量部位最近刚练过，今天更适合散步、游泳、拉伸或休息，给肌肉恢复时间。',
    );
  }

  switch (best) {
    case MuscleGroup.chest:
    case MuscleGroup.shoulders:
    case MuscleGroup.arms:
      return const GymMuscleSuggestion(
        name: '上肢推（胸肩手臂）',
        hint: '胸部、肩部、手臂有一段时间没练了，今天推类训练很合适。',
      );
    case MuscleGroup.back:
      return const GymMuscleSuggestion(
        name: '背部',
        hint: '背部肌肉最近没怎么练，拉类训练可以帮助改善体态。',
      );
    case MuscleGroup.glutesAndLegs:
      return const GymMuscleSuggestion(
        name: '臀腿',
        hint: '臀腿是人体最大的肌群，训练收益很高，今天很适合练。',
      );
    case MuscleGroup.core:
      return const GymMuscleSuggestion(
        name: '核心',
        hint: '核心力量影响几乎所有动作，今天很适合安排腹肌与核心稳定训练。',
      );
  }
}
