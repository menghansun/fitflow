import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_session.dart';
import '../models/body_metrics.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseService get instance => _instance;
  static final SupabaseService _instance = SupabaseService._();

  bool get isInitialized => Supabase.instance.isInitialized;
  String? get uid => Supabase.instance.client.auth.currentUser?.id;

  /// Initialize Supabase (call in main.dart before runApp)
  static Future<void> init(String url, String anonKey) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  SupabaseClient get _db => Supabase.instance.client;

  // ── Auth ─────────────────────────────────────────────────

  /// Register with email + password
  static Future<User> register(String email, String password) async {
    final res = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
    if (res.user == null) throw Exception('注册未成功，请稍后重试');
    return res.user!;
  }

  /// Login with email + password
  static Future<User> login(String email, String password) async {
    final res = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.user!;
  }

  /// Logout
  static Future<void> logout() => Supabase.instance.client.auth.signOut();

  /// Stream auth state changes
  static Stream<User?> get authStateChanges =>
      Supabase.instance.client.auth.onAuthStateChange.map((event) => event.session?.user);

  // ── Profile ──────────────────────────────────────────────

  /// Save user profile to Supabase
  Future<void> saveProfile({
    required String nickname,
    String? avatarEmoji,
    DateTime? createdAt,
    double? height,
  }) async {
    final userId = uid;
    if (userId == null) return;

    await _db.from('profiles').upsert({
      'id': userId,
      'nickname': nickname,
      'avatar_emoji': avatarEmoji,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'height': height,
    });
  }

  /// Fetch user profile from Supabase
  Future<Map<String, dynamic>?> fetchProfile() async {
    final userId = uid;
    if (userId == null) return null;

    try {
      final res = await _db
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return res;
    } catch (_) {
      return null;
    }
  }

  // ── Workouts ─────────────────────────────────────────────

  List<Map<String, dynamic>>? _serializeSwimSets(List<SwimSet>? swimSets) {
    if (swimSets == null) return null;
    return swimSets
        .map((set) => {
              'style': set.style.name,
              'distance_meters': set.distanceMeters,
            })
        .toList();
  }

  List<SwimSet>? _deserializeSwimSets(dynamic raw) {
    if (raw == null) return null;
    if (raw is! List) return null;

    final result = <SwimSet>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final styleRaw = item['style'];
      final distanceRaw = item['distance_meters'];
      if (styleRaw is! String || distanceRaw == null) continue;

      final style = SwimStyle.values.where((e) => e.name == styleRaw).firstOrNull;
      final distanceMeters = switch (distanceRaw) {
        int v => v,
        double v => v.toInt(),
        String v => int.tryParse(v),
        _ => null,
      };

      if (style == null || distanceMeters == null) continue;
      result.add(SwimSet(style: style, distanceMeters: distanceMeters));
    }

    return result.isEmpty ? null : result;
  }

  // ── Gym Exercises ─────────────────────────────────────

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
          final reps = gs['reps'];
          final weight = gs['weight'];
          final duration = gs['duration_seconds'];
          final isBw = gs['is_bodyweight'];
          sets.add(GymSet(
            reps: reps is int ? reps : 0,
            weight: weight is num ? weight.toDouble() : 0.0,
            durationSeconds: duration is int ? duration : 0,
            isBodyweight: isBw is bool ? isBw : false,
          ));
        }
      }

      result.add(GymExercise(
        name: nameRaw,
        muscleGroup: muscleGroup,
        sets: sets,
      ));
    }

    return result.isEmpty ? null : result;
  }

  /// Sync multiple workout sessions to Supabase in one batch
  Future<void> syncSessions(List<WorkoutSession> sessions) async {
    final userId = uid;
    if (userId == null) {
      throw Exception('Cannot sync: user not logged in (uid is null)');
    }

    final rows = sessions.map((s) => {
      'id': s.id,
      'user_id': userId,
      'session_date': s.date.toIso8601String(),
      'type': s.type.name,
      'duration_seconds': s.durationSeconds,
      'heart_rate_avg': s.heartRateAvg,
      'heart_rate_max': s.heartRateMax,
      'calories': s.calories,
      'pool_length_meters': s.poolLengthMeters,
      'total_distance_meters': s.totalDistanceMeters,
      'notes': s.notes,
      'duration_minutes': s.durationMinutes,
      'laps': s.laps,
      'avg_pace': s.avgPace,
      'swolf_avg': s.swolfAvg,
      'stroke_count': s.strokeCount,
      'cardio_type': s.cardioType,
      'end_date': s.endDate?.toIso8601String(),
      'counts_as_workout': s.countsAsWorkout,
      'local_updated_at': DateTime.now().millisecondsSinceEpoch,
      'swim_sets': _serializeSwimSets(s.swimSets),
      'exercises': _serializeGymExercises(s.exercises),
    }).toList();

    await _db.from('workouts').upsert(rows);
  }

  /// Sync a single workout session to Supabase
  Future<void> syncSession(WorkoutSession session) async {
    await syncSessions([session]);
  }

  /// Delete a workout session from Supabase
  Future<void> deleteSession(String sessionId) async {
    final userId = uid;
    if (userId == null) return;

    await _db.from('workouts').delete().eq('id', sessionId).eq('user_id', userId);
  }

  /// Force-push ALL local sessions to cloud, overwriting any stale cloud data.
  /// Use this for one-time backfill after fixing a sync bug.
  Future<void> forcePushAllToCloud(List<WorkoutSession> sessions) async {
    final userId = uid;
    if (userId == null) return;
    await syncSessions(sessions);
  }

  /// Fetch all cloud sessions for current user
  Future<List<WorkoutSession>> fetchSessions() async {
    final userId = uid;
    if (userId == null) return [];

    try {
      final res = await _db
          .from('workouts')
          .select()
          .eq('user_id', userId);
      return (res as List).map((row) {
        return WorkoutSession(
          id: row['id'] as String,
          date: DateTime.parse(row['session_date'] as String),
          type: WorkoutType.values.firstWhere(
            (e) => e.name == row['type'],
            orElse: () => WorkoutType.other,
          ),
          durationSeconds: row['duration_seconds'] as int? ?? 0,
          heartRateAvg: row['heart_rate_avg'] as int?,
          heartRateMax: row['heart_rate_max'] as int?,
          calories: row['calories'] as int?,
          swimSets: _deserializeSwimSets(row['swim_sets']),
          poolLengthMeters: row['pool_length_meters'] as int?,
          totalDistanceMeters: row['total_distance_meters'] as int?,
          notes: row['notes'] as String?,
          durationMinutes: row['duration_minutes'] as int?,
          laps: row['laps'] as int?,
          avgPace: row['avg_pace'] as String?,
          swolfAvg: row['swolf_avg'] as int?,
          strokeCount: row['stroke_count'] as int?,
          cardioType: row['cardio_type'] as String?,
          endDate: row['end_date'] != null
              ? DateTime.parse(row['end_date'] as String)
              : null,
          exercises: _deserializeGymExercises(row['exercises']),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Body Metrics ────────────────────────────────────────

  /// Sync body metrics records to Supabase
  Future<void> syncBodyMetrics(List<BodyMetrics> records) async {
    final userId = uid;
    if (userId == null) {
      throw Exception('Cannot sync: user not logged in (uid is null)');
    }

    final rows = records.map((r) => {
      'id': r.id,
      'user_id': userId,
      'date': r.date.toIso8601String(),
      'weight': r.weight,
      'height': r.height,
      'body_fat_percentage': r.bodyFatPercentage,
      'muscle_mass': r.muscleMass,
      'basal_metabolic_rate': r.basalMetabolicRate,
      'notes': r.notes,
    }).toList();

    await _db.from('body_metrics').upsert(rows);
  }

  /// Fetch all cloud body metrics for current user
  Future<List<BodyMetrics>> fetchBodyMetrics() async {
    final userId = uid;
    if (userId == null) return [];

    try {
      final res = await _db
          .from('body_metrics')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      return (res as List).map((row) {
        return BodyMetrics(
          id: row['id'] as String,
          date: DateTime.parse(row['date'] as String),
          weight: (row['weight'] as num?)?.toDouble(),
          height: (row['height'] as num?)?.toDouble(),
          bodyFatPercentage: (row['body_fat_percentage'] as num?)?.toDouble(),
          muscleMass: (row['muscle_mass'] as num?)?.toDouble(),
          basalMetabolicRate: row['basal_metabolic_rate'] as int?,
          notes: row['notes'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Delete a body metrics record from Supabase
  Future<void> deleteBodyMetrics(String id) async {
    final userId = uid;
    if (userId == null) return;
    await _db.from('body_metrics').delete().eq('id', id).eq('user_id', userId);
  }
}
