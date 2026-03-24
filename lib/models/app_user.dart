import 'package:hive/hive.dart';

part 'app_user.g.dart';

@HiveType(typeId: 7)
class AppUser extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String nickname;

  @HiveField(2)
  String? avatarEmoji;

  @HiveField(3)
  late int themeModeIndex; // 0=system, 1=light, 2=dark

  @HiveField(4)
  late DateTime createdAt;

  AppUser({
    required this.id,
    required this.nickname,
    this.avatarEmoji,
    this.themeModeIndex = 0,
    required this.createdAt,
  });

  static const List<String> defaultAvatars = [
    '🏊', '🏋️', '🧘', '🚴', '🏃', '⚽', '🎯', '💪',
    '🦁', '🐯', '🦊', '🐼', '🐸', '🦋', '🌟', '🔥',
  ];
}
