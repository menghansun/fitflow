import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/achievement.dart';
import '../theme/app_theme.dart';

class AchievementUnlockDialog extends StatelessWidget {
  final Achievement achievement;

  const AchievementUnlockDialog({
    super.key,
    required this.achievement,
  });

  // 用户自定义图标URL
  static const String _iconUrl =
      'https://minimax-algeng-chat-tts.oss-cn-wulanchabu.aliyuncs.com/ccv2%2F2026-03-26%2FMiniMax-M2.7%2F2031253183187128423%2Fc9e441477332a88e5839e9cd2cd5c2e0466f46cd6d72c01306f178caccab4d81..png';

  // 调侃话语列表
  static const List<String> _jokes = [
    '太棒了！继续保持，肌肉在向你招手！💪',
    '哇哦！这是要成为运动达人的节奏吗？🏃',
    '厉害！连太阳都在为你燃烧卡路里！☀️',
    '太牛了！你就是健身房最靓的仔！😎',
    '不错不错！距离马甲线又近了一步！🏋️',
    '666！朋友都在问你是怎么做到的！🤙',
    '这就是实力！继续保持，别骄傲哦~😏',
    '解锁成就！你的身体已经记住这种感觉了！🎉',
    '太秀了！你就是自律本人！💯',
    '恭喜恭喜！这份荣誉你值得拥有！🏆',
  ];

  String get _randomJoke {
    final index = achievement.title.hashCode % _jokes.length.abs();
    return _jokes[index.abs()];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: primary.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部装饰
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary.withValues(alpha: 0.8),
                    primary.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: ClipOval(
                  child: Image.network(
                    _iconUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        achievement.icon,
                        style: const TextStyle(fontSize: 40),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 标题
            Text(
              '成就解锁',
              style: TextStyle(
                fontSize: 14,
                color: primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),

            // 成就名称
            Text(
              achievement.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : null,
              ),
            ),
            const SizedBox(height: 4),

            // 成就描述
            Text(
              achievement.description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // 达成时间
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDateTime(achievement.unlockedAt ?? DateTime.now()),
                    style: TextStyle(
                      fontSize: 13,
                      color: primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 调侃话语
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard.withValues(alpha: 0.5)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _randomJoke,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 确定按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '太棒了！',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小时前';
    } else {
      return '${dateTime.month}月${dateTime.day}日 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

// 显示成就解锁弹窗
Future<void> showAchievementUnlockDialog(
  BuildContext context,
  Achievement achievement,
) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AchievementUnlockDialog(achievement: achievement),
  );
}
