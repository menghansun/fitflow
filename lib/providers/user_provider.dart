import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_user.dart';
import '../models/workout_session.dart';
import '../services/supabase_service.dart';

class UserProvider extends ChangeNotifier {
  static const String _usersBoxName = 'app_users';
  static const String _currentUserKey = 'current_user_id';

  AppUser? _currentUser;
  List<AppUser> _allUsers = [];
  bool _initialized = false;

  AppUser? get currentUser => _currentUser;
  List<AppUser> get allUsers => _allUsers;
  bool get initialized => _initialized;
  bool get hasUsers => _allUsers.isNotEmpty;

  // Hive box name for current user's workouts
  String get workoutBoxName =>
      _currentUser != null ? 'workouts_${_currentUser!.id}' : 'workouts_default';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_usersBoxName)) {
      await Hive.openBox<AppUser>(_usersBoxName);
    }
    _allUsers = Hive.box<AppUser>(_usersBoxName).values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // If LeanCloud user is logged in, ensure local profile exists
    final lcUid = SupabaseService.instance.uid;
    if (lcUid != null) {
      final existing = _allUsers.where((u) => u.id == lcUid).toList();
      if (existing.isNotEmpty) {
        _currentUser = existing.first;
        // Always try to fetch latest profile from cloud and update local
        final cloudProfile = await SupabaseService.instance.fetchProfile();
        if (cloudProfile != null && cloudProfile.isNotEmpty) {
          final cloudNickname = cloudProfile['nickname'] as String?;
          final cloudAvatar = cloudProfile['avatar_emoji'] as String?;
          if (cloudNickname?.isNotEmpty == true) {
            _currentUser!.nickname = cloudNickname!;
          }
          if (cloudAvatar != null) {
            _currentUser!.avatarEmoji = cloudAvatar;
          }
          await Hive.box<AppUser>(_usersBoxName).put(_currentUser!.id, _currentUser!);
        }
      } else {
        // First time on this device: try to fetch profile from cloud
        final cloudProfile = await SupabaseService.instance.fetchProfile();
        if (cloudProfile != null && cloudProfile.isNotEmpty) {
          final user = AppUser(
            id: lcUid,
            nickname: cloudProfile['nickname'] as String? ?? '我',
            avatarEmoji: cloudProfile['avatar_emoji'] as String?,
            themeModeIndex: cloudProfile['theme_mode_index'] as int? ?? 0,
            createdAt: cloudProfile['created_at'] != null
                ? DateTime.parse(cloudProfile['created_at'] as String)
                : DateTime.now(),
          );
          await Hive.box<AppUser>(_usersBoxName).put(user.id, user);
          _allUsers.add(user);
          _currentUser = user;
        } else {
          // No cloud profile: create local with email as default name
          final email = SupabaseService.instance.uid ?? '我';
          final user = AppUser(
            id: lcUid,
            nickname: email.split('@').first,
            avatarEmoji: '💪',
            createdAt: DateTime.now(),
          );
          await Hive.box<AppUser>(_usersBoxName).put(user.id, user);
          await SupabaseService.instance.saveProfile(
            nickname: user.nickname,
            avatarEmoji: user.avatarEmoji,
            themeModeIndex: 0,
            createdAt: user.createdAt,
          );
          _allUsers.add(user);
          _currentUser = user;
        }
      }
    }

    // Restore last active user if no LeanCloud user
    if (_currentUser == null) {
      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getString(_currentUserKey);
      if (lastId != null) {
        final match = _allUsers.where((u) => u.id == lastId).toList();
        if (match.isNotEmpty) {
          _currentUser = match.first;
        } else if (_allUsers.isNotEmpty) {
          _currentUser = _allUsers.first;
        }
      } else if (_allUsers.isNotEmpty) {
        _currentUser = _allUsers.first;
      }
    }

    // Ensure workout box is open for current user
    if (_currentUser != null) {
      await _ensureWorkoutBox(_currentUser!.id);
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> _ensureWorkoutBox(String userId) async {
    final boxName = 'workouts_$userId';
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<WorkoutSession>(boxName);
    }
  }

  /// After password login/registration: ensure a local profile exists for workouts.
  Future<void> ensureLocalProfileAfterAuth(String nickname) async {
    final name = nickname.trim();
    final lcUid = SupabaseService.instance.uid;
    if (lcUid == null) return;

    // Always try to fetch latest cloud profile first
    final cloud = await SupabaseService.instance.fetchProfile();

    if (!_allUsers.any((u) => u.id == lcUid)) {
      // No local user: use cloud data or create new
      final user = AppUser(
        id: lcUid,
        nickname: (cloud?['nickname'] as String?)?.isNotEmpty == true
            ? cloud!['nickname'] as String
            : (name.isEmpty ? '我' : name),
        avatarEmoji: cloud?['avatar_emoji'] as String? ?? '💪',
        themeModeIndex: cloud?['theme_mode_index'] as int? ?? 0,
        createdAt: (cloud?['created_at'] as String?)?.isNotEmpty == true
            ? DateTime.parse(cloud!['created_at'] as String)
            : DateTime.now(),
      );
      await Hive.box<AppUser>(_usersBoxName).put(user.id, user);
      _allUsers.add(user);
      _currentUser = user;
      await _ensureWorkoutBox(user.id);
      notifyListeners();
    } else {
      // Local user exists: update from cloud if available
      final existing = _allUsers.firstWhere((u) => u.id == lcUid);
      if (cloud != null && cloud.isNotEmpty) {
        final cloudNick = cloud['nickname'] as String?;
        final cloudAvatar = cloud['avatar_emoji'] as String?;
        if (cloudNick?.isNotEmpty == true) existing.nickname = cloudNick!;
        if (cloudAvatar != null) existing.avatarEmoji = cloudAvatar;
        await Hive.box<AppUser>(_usersBoxName).put(existing.id, existing);
      }
      _currentUser = existing;
      await _ensureWorkoutBox(existing.id);
      notifyListeners();
    }
  }

  Future<AppUser> createUser(String nickname, String? avatarEmoji) async {
    final user = AppUser(
      id: const Uuid().v4(),
      nickname: nickname,
      avatarEmoji: avatarEmoji ?? '💪',
      createdAt: DateTime.now(),
    );
    await Hive.box<AppUser>(_usersBoxName).put(user.id, user);
    await _ensureWorkoutBox(user.id);
    _allUsers.add(user);
    // Auto-select if first user
    if (_allUsers.length == 1) {
      await switchUser(user.id);
    } else {
      notifyListeners();
    }
    // Sync to cloud if logged in
    SupabaseService.instance.saveProfile(
      nickname: nickname,
      avatarEmoji: avatarEmoji ?? '💪',
      themeModeIndex: 0,
      createdAt: user.createdAt,
    );
    return user;
  }

  Future<void> switchUser(String userId) async {
    final user = _allUsers.firstWhere((u) => u.id == userId);
    await _ensureWorkoutBox(userId);
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, userId);
    notifyListeners();
  }

  Future<void> updateUser(AppUser user) async {
    await Hive.box<AppUser>(_usersBoxName).put(user.id, user);
    final idx = _allUsers.indexWhere((u) => u.id == user.id);
    if (idx >= 0) _allUsers[idx] = user;
    if (_currentUser?.id == user.id) _currentUser = user;
    SupabaseService.instance.saveProfile(
      nickname: user.nickname,
      avatarEmoji: user.avatarEmoji,
      themeModeIndex: user.themeModeIndex,
      createdAt: user.createdAt,
    );
    notifyListeners();
  }

  Future<void> deleteUser(String userId) async {
    await Hive.box<AppUser>(_usersBoxName).delete(userId);
    // Also delete workout data
    final boxName = 'workouts_$userId';
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box<WorkoutSession>(boxName).deleteFromDisk();
    }
    _allUsers.removeWhere((u) => u.id == userId);
    if (_currentUser?.id == userId) {
      _currentUser = _allUsers.isNotEmpty ? _allUsers.first : null;
      if (_currentUser != null) {
        await _ensureWorkoutBox(_currentUser!.id);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_currentUserKey, _currentUser!.id);
      }
    }
    notifyListeners();
  }

  ThemeMode get currentThemeMode {
    final idx = _currentUser?.themeModeIndex ?? 0;
    return ThemeMode.values[idx];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_currentUser == null) return;
    _currentUser!.themeModeIndex = mode.index;
    await updateUser(_currentUser!);
  }
}
