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
  late DateTime createdAt;

  @HiveField(4)
  double? height; // 身高 (cm)

  AppUser({
    required this.id,
    required this.nickname,
    this.avatarEmoji,
    required this.createdAt,
    this.height,
  });

  static const List<String> defaultAvatars = [
    '🏊', '🏋️', '🧘', '🚴', '🏃', '⚽', '🎯', '💪',
    '🦁', '🐯', '🦊', '🐼', '🐸', '🦋', '🌟', '🔥',
  ];
}
