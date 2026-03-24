import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/motivation_service.dart';

/// 记录成功弹窗（带弹跳 + 烟花粒子动画）
Future<void> showSuccessDialog({
  required BuildContext context,
  required String typeKey,     // 'swim' | 'cardio' | 'gym'
  required String typeEmoji,
  required String typeLabel,
  required String detailText,  // 如 "跑步  32 分钟 · 5.0 km"
  required bool isEdit,
}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (ctx, anim1, anim2) => _SuccessDialog(
      typeKey: typeKey,
      typeEmoji: typeEmoji,
      typeLabel: typeLabel,
      detailText: detailText,
      isEdit: isEdit,
    ),
    transitionBuilder: (ctx, anim1, anim2, child) {
      // 弹跳进场
      final curved = CurvedAnimation(
        parent: anim1,
        curve: Curves.elasticOut,
      );
      return ScaleTransition(
        scale: Tween<double>(begin: 0.5, end: 1.0).animate(curved),
        child: FadeTransition(
          opacity: anim1,
          child: child,
        ),
      );
    },
  );
}

class _SuccessDialog extends StatefulWidget {
  final String typeKey;
  final String typeEmoji;
  final String typeLabel;
  final String detailText;
  final bool isEdit;

  const _SuccessDialog({
    required this.typeKey,
    required this.typeEmoji,
    required this.typeLabel,
    required this.detailText,
    required this.isEdit,
  });

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _particleCtrl;
  late final String _quote;

  @override
  void initState() {
    super.initState();
    _quote = MotivationService.forWorkoutType(widget.typeKey);
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    super.dispose();
  }

  Color get _accentColor => switch (widget.typeKey) {
        'swim' => AppColors.swimAccent,
        'cardio' => AppColors.cardioAccent,
        _ => AppColors.gymAccent,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentColor;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // 粒子层
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: const Size(320, 320),
                painter: _ConfettiPainter(
                  progress: _particleCtrl.value,
                  color: accent,
                ),
              ),
            ),

            // 卡片
            Container(
              width: 300,
              margin: const EdgeInsets.only(top: 60),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji 大图标
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (_, v, __) => Transform.scale(
                      scale: v,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.typeEmoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 标题
                  Text(
                    widget.isEdit ? '修改成功！' : '记录成功！',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 详情
                  Text(
                    widget.detailText,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // 激励语气泡
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _quote,
                      style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 完成按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        '太棒了！',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 简易彩带粒子 painter ──────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Color color;

  // 固定的粒子参数（避免每帧 Random 导致闪烁）
  static final _particles = List.generate(18, (i) {
    final angle = (i / 18) * 3.14159 * 2;
    return (angle: angle, speed: 0.6 + (i % 3) * 0.2, size: 4.0 + (i % 4) * 2.0);
  });

  const _ConfettiPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress > 0.85) return; // 消散
    final center = Offset(size.width / 2, size.height * 0.38);
    final opacity = (1 - progress / 0.85).clamp(0.0, 1.0);

    for (final p in _particles) {
      final dist = p.speed * progress * 130;
      final dx = center.dx + dist * (0.5 - p.speed * 0.3) * 2 * (p.angle - 3.14).sign;
      final dy = center.dy - dist * 0.7 + progress * progress * 60;
      final paint = Paint()
        ..color = color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dx, dy), p.size / 2, paint);

      // 彩带条（另一种颜色）
      final paint2 = Paint()
        ..color = Colors.amber.withValues(alpha: opacity * 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              center.dx - dx + center.dx * 0.3,
              center.dy - dy * 0.6,
            ),
            width: p.size * 0.7,
            height: p.size * 1.8,
          ),
          const Radius.circular(2),
        ),
        paint2,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────
//  里程碑弹窗
// ─────────────────────────────────────────────────────────
Future<void> showMilestoneBanner({
  required BuildContext context,
  required int streak,
  required String quote,
}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (ctx, anim1, anim2) => _MilestoneDialog(
      streak: streak,
      quote: quote,
    ),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0, -0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack));
      return SlideTransition(
        position: slide,
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
  );
}

class _MilestoneDialog extends StatefulWidget {
  final int streak;
  final String quote;
  const _MilestoneDialog({required this.streak, required this.quote});

  @override
  State<_MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<_MilestoneDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF2A2A4A), const Color(0xFF1A1A2E)]
                  : [const Color(0xFFFFF8E1), const Color(0xFFFFF3CD)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 闪光数字
              AnimatedBuilder(
                animation: _shimmerCtrl,
                builder: (_, __) {
                  return ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: const [
                        Colors.amber,
                        Colors.yellow,
                        Colors.orange,
                        Colors.amber,
                      ],
                      stops: [
                        (_shimmerCtrl.value - 0.3).clamp(0.0, 1.0),
                        _shimmerCtrl.value.clamp(0.0, 1.0),
                        (_shimmerCtrl.value + 0.1).clamp(0.0, 1.0),
                        (_shimmerCtrl.value + 0.4).clamp(0.0, 1.0),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      '🔥 ${widget.streak} 天',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              Text(
                '连续打卡里程碑',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                widget.quote,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '继续加油！',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ������������������������������������������������������������������������������������������������������������������
//  ���������̱���������ͨ�ã�
// ������������������������������������������������������������������������������������������������������������������
Future<void> checkAndShowMilestone(BuildContext context, int streak) async {
  final quote = MotivationService.forStreak(streak);
  if (quote == null) return;
  if (!context.mounted) return;
  await showMilestoneBanner(context: context, streak: streak, quote: quote);
}
