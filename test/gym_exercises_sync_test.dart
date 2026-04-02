import 'package:flutter_test/flutter_test.dart';
import 'package:fitflow/models/workout_session.dart';

void main() {
  group('GymExercise serialization round-trip', () {
    test('GymExercise with all fields serializes and deserializes correctly', () {
      final gymSets = [
        GymSet(reps: 10, weight: 20.0, durationSeconds: 0, isBodyweight: false),
        GymSet(reps: 8, weight: 25.0, durationSeconds: 0, isBodyweight: false),
      ];
      final exercises = [
        GymExercise(name: '杠铃卧推', muscleGroup: MuscleGroup.chest, sets: gymSets),
      ];
      final session = WorkoutSession(
        id: 'test-001',
        date: DateTime(2026, 3, 15),
        type: WorkoutType.gym,
        durationSeconds: 3600,
        exercises: exercises,
      );

      // Simulate cloud format (what Supabase stores/returns)
      final cloudFormat = _simulateSerialize(session);

      // Verify cloud format has exercises field
      expect(cloudFormat['exercises'], isNotNull);
      expect(cloudFormat['exercises'], isA<List>());
      expect((cloudFormat['exercises'] as List).length, 1);

      final exList = cloudFormat['exercises'] as List;
      expect(exList[0]['name'], '杠铃卧推');
      expect(exList[0]['muscle_group'], 'chest');
      expect(exList[0]['sets'], isA<List>());
      expect((exList[0]['sets'] as List).length, 2);
      expect(exList[0]['sets'][0]['weight'], 20.0);
      expect(exList[0]['sets'][0]['reps'], 10);

      // Verify deserialization
      final deserialized = _simulateDeserialize(cloudFormat);
      expect(deserialized.exercises, isNotNull);
      expect(deserialized.exercises!.length, 1);
      expect(deserialized.exercises![0].name, '杠铃卧推');
      expect(deserialized.exercises![0].muscleGroup, MuscleGroup.chest);
      expect(deserialized.exercises![0].sets.length, 2);
      expect(deserialized.exercises![0].sets[0].weight, 20.0);
      expect(deserialized.exercises![0].sets[0].reps, 10);
    });

    test('Session without exercises serializes null', () {
      final session = WorkoutSession(
        id: 'test-002',
        date: DateTime(2026, 3, 16),
        type: WorkoutType.gym,
        durationSeconds: 1800,
        exercises: null,
      );

      final cloudFormat = _simulateSerialize(session);
      expect(cloudFormat['exercises'], isNull);
    });

    test('Multiple muscle groups round-trip correctly', () {
      final exercises = [
        GymExercise(name: '引体向上', muscleGroup: MuscleGroup.back, sets: [
          GymSet(reps: 8, weight: 0, durationSeconds: 0, isBodyweight: true),
        ]),
        GymExercise(name: '驴踢', muscleGroup: MuscleGroup.glutes, sets: [
          GymSet(reps: 12, weight: 0, durationSeconds: 0, isBodyweight: true),
        ]),
        GymExercise(name: '侧平举', muscleGroup: MuscleGroup.shoulders, sets: [
          GymSet(reps: 15, weight: 5.0, durationSeconds: 0, isBodyweight: false),
        ]),
      ];
      final session = WorkoutSession(
        id: 'test-003',
        date: DateTime(2026, 3, 17),
        type: WorkoutType.gym,
        durationSeconds: 4500,
        exercises: exercises,
      );

      final cloudFormat = _simulateSerialize(session);
      final deserialized = _simulateDeserialize(cloudFormat);

      expect(deserialized.exercises!.length, 3);
      expect(deserialized.exercises![0].muscleGroup, MuscleGroup.back);
      expect(deserialized.exercises![1].muscleGroup, MuscleGroup.glutes);
      expect(deserialized.exercises![2].muscleGroup, MuscleGroup.shoulders);
    });

    test('Swim session (no exercises) round-trips correctly', () {
      final session = WorkoutSession(
        id: 'test-004',
        date: DateTime(2026, 3, 18),
        type: WorkoutType.swim,
        durationSeconds: 2700,
        swimSets: [
          SwimSet(style: SwimStyle.freestyle, distanceMeters: 1000),
        ],
      );

      final cloudFormat = _simulateSerialize(session);
      expect(cloudFormat['exercises'], isNull);
      expect(cloudFormat['swim_sets'], isNotNull);
    });
  });
}

// ── Simulate cloud serialization (mirrors SupabaseService) ──────────────────

Map<String, dynamic> _simulateSerialize(WorkoutSession s) {
  return {
    'id': s.id,
    'user_id': 'test-user',
    'session_date': s.date.toIso8601String(),
    'type': s.type.name,
    'duration_seconds': s.durationSeconds,
    'swim_sets': _serializeSwimSets(s.swimSets),
    'exercises': _serializeGymExercises(s.exercises),
  };
}

WorkoutSession _simulateDeserialize(Map<String, dynamic> row) {
  return WorkoutSession(
    id: row['id'] as String,
    date: DateTime.parse(row['session_date'] as String),
    type: WorkoutType.values.firstWhere(
      (e) => e.name == row['type'],
      orElse: () => WorkoutType.other,
    ),
    durationSeconds: row['duration_seconds'] as int? ?? 0,
    swimSets: _deserializeSwimSets(row['swim_sets']),
    exercises: _deserializeGymExercises(row['exercises']),
  );
}

List<Map<String, dynamic>>? _serializeSwimSets(List<SwimSet>? swimSets) {
  if (swimSets == null) return null;
  return swimSets.map((set) => {
    'style': set.style.name,
    'distance_meters': set.distanceMeters,
  }).toList();
}

List<SwimSet>? _deserializeSwimSets(dynamic raw) {
  if (raw == null) return null;
  if (raw is! List) return null;
  final result = <SwimSet>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final style = SwimStyle.values.where((e) => e.name == item['style']).firstOrNull;
    final dist = item['distance_meters'];
    if (style == null || dist == null) continue;
    result.add(SwimSet(style: style, distanceMeters: dist is int ? dist : (dist as double).toInt()));
  }
  return result.isEmpty ? null : result;
}

List<Map<String, dynamic>>? _serializeGymExercises(List<GymExercise>? exercises) {
  if (exercises == null) return null;
  return exercises.map((ex) => {
    'name': ex.name,
    'muscle_group': ex.muscleGroup.name,
    'sets': ex.sets.map((gs) => {
      'reps': gs.reps,
      'weight': gs.weight,
      'duration_seconds': gs.durationSeconds,
      'is_bodyweight': gs.isBodyweight,
    }).toList(),
  }).toList();
}

List<GymExercise>? _deserializeGymExercises(dynamic raw) {
  if (raw == null) return null;
  if (raw is! List) return null;
  final result = <GymExercise>[];
  for (final ex in raw) {
    if (ex is! Map) continue;
    final nameRaw = ex['name'];
    final mgRaw = ex['muscle_group'];
    final setsRaw = ex['sets'];
    if (nameRaw is! String || mgRaw is! String) continue;
    final muscleGroup = MuscleGroup.values.where((e) => e.name == mgRaw).firstOrNull;
    if (muscleGroup == null) continue;
    final sets = <GymSet>[];
    if (setsRaw is List) {
      for (final gs in setsRaw) {
        if (gs is! Map) continue;
        sets.add(GymSet(
          reps: gs['reps'] is int ? gs['reps'] : 0,
          weight: (gs['weight'] is num) ? (gs['weight'] as num).toDouble() : 0.0,
          durationSeconds: gs['duration_seconds'] is int ? gs['duration_seconds'] : 0,
          isBodyweight: gs['is_bodyweight'] is bool ? gs['is_bodyweight'] : false,
        ));
      }
    }
    result.add(GymExercise(name: nameRaw, muscleGroup: muscleGroup, sets: sets));
  }
  return result.isEmpty ? null : result;
}
