import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/workout_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/session_card.dart';
import '../../services/motivation_service.dart';
import '../session_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer2<WorkoutProvider, UserProvider>(
          builder: (context, workoutProvider, userProvider, _) {
            final theme = Theme.of(context);
            final now = DateTime.now();
            final weekStart =
                now.subtract(Duration(days: now.weekday - 1));
            final weekEnd = weekStart.add(const Duration(days: 6));
            final weekCount = workoutProvider.getWorkoutCountForPeriod(
                weekStart, weekEnd);
            final weekMins = workoutProvider
                    .getTotalDurationForPeriod(weekStart, weekEnd) ~/
                60;
            final todayCount = workoutProvider
                .getSessionsForDate(now)
                .where((s) => s.countsAsWorkout)
                .length;

            return CustomScrollView(
              slivers: [
                // ── Weekly card ─────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _WeeklySummaryCard(
                      weekCount: weekCount,
                      weekMins: weekMins,
                      todayCount: todayCount,
                    ),
                  ),
                ),

                // ── 每日一句 ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _DailyQuoteCard(),
                  ),
                ),

                // ── 运动价值 ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _ValueCard(
                      totalSessions: workoutProvider.sessions
                          .where((s) => s.countsAsWorkout)
                          .length,
                      monthSessions: workoutProvider
                          .getSessionsForMonth(now.year, now.month)
                          .where((s) => s.countsAsWorkout)
                          .length,
                      yearSessions: workoutProvider
                          .getWorkoutCountForPeriod(
                            DateTime(now.year, 1, 1),
                            DateTime(now.year, 12, 31, 23, 59, 59),
                          ),
                    ),
                  ),
                ),

                // ── Recent header ──────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text('最近记录',
                        style: theme.textTheme.titleLarge),
                  ),
                ),

                // ── Session list ───────────────────────
                workoutProvider.recentSessions.isEmpty
                    ? SliverToBoxAdapter(
                        child: _EmptyState(),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final s = workoutProvider
                                .recentSessions[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 6),
                              child: SessionCard(
                                session: s,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) =>
                                        SessionDetailScreen(session: s))),
                                onDelete: () => workoutProvider.deleteSession(s.id),
                              ),
                            );
                          },
                          childCount: workoutProvider
                              .recentSessions.length,
                        ),
                      ),

                const SliverToBoxAdapter(
                    child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── 运动价值卡片 ─────────────────────────────────────────────

class _ValueCard extends StatefulWidget {
  final int totalSessions;
  final int monthSessions;
  final int yearSessions;

  const _ValueCard({
    required this.totalSessions,
    required this.monthSessions,
    required this.yearSessions,
  });

  @override
  State<_ValueCard> createState() => _ValueCardState();
}

class _ValueCardState extends State<_ValueCard> {
  static const String _prefKey = 'price_per_session';
  static const String _prefKeyTarget = 'target_value';
  int _price = 40;
  int _targetValue = 10000;

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _price = prefs.getInt(_prefKey) ?? 40;
      _targetValue = prefs.getInt(_prefKeyTarget) ?? 10000;
    });
  }

  Future<void> _editPrice() async {
    final priceCtrl = TextEditingController(text: '$_price');
    final targetCtrl = TextEditingController(text: '$_targetValue');
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('设置运动价值'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: '单次价值 ¥ ',
                suffixText: '/ 次',
                hintText: '如 40',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '回本目标 ¥ ',
                hintText: '如 10000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result == true) {
      final price = int.tryParse(priceCtrl.text.trim());
      final target = int.tryParse(targetCtrl.text.trim());
      if (price != null && price > 0) {
        setState(() => _price = price);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_prefKey, price);
      }
      if (target != null && target > 0) {
        setState(() => _targetValue = target);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_prefKeyTarget, target);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = widget.totalSessions * _price;
    final monthValue = widget.monthSessions * _price;

    // 计算回本倒计时
    String countdownText() {
      if (totalValue >= _targetValue) return '已达成';
      final remaining = _targetValue - totalValue;
      final sessionsNeeded = (remaining / _price).ceil();
      return '$sessionsNeeded 次';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A2E), Color(0xFF2D1654)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1D95).withValues(alpha:0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 背景装饰圆
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFBBF24).withValues(alpha:0.07),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFBBF24).withValues(alpha:0.05),
              ),
            ),
          ),
          // 内容
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💰', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    const Text(
                      '运动价值',
                      style: TextStyle(
                        color: Color(0xFFDDD6FE),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _editPrice,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFBBF24).withValues(alpha:0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '¥$_price / 次',
                              style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_outlined,
                                color: Color(0xFFFBBF24), size: 11),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '¥',
                      style: TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$totalValue',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '累计 ${widget.totalSessions} 次运动，节省的健身费用',
                  style: const TextStyle(
                    color: Color(0xFF9D86CC),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                // 回本目标进度
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '回本目标',
                            style: TextStyle(
                              color: Color(0xFF9D86CC),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '¥$totalValue / ¥$_targetValue',
                            style: const TextStyle(
                              color: Color(0xFFDDD6FE),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalValue > _targetValue
                              ? 1.0
                              : totalValue / _targetValue,
                          backgroundColor: Colors.white.withValues(alpha:0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            totalValue >= _targetValue
                                ? const Color(0xFF34D399)
                                : const Color(0xFFFBBF24),
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        totalValue >= _targetValue
                            ? '✅ 已达成目标！'
                            : '还差 ¥${_targetValue - totalValue} 达成目标',
                        style: TextStyle(
                          color: totalValue >= _targetValue
                              ? const Color(0xFF34D399)
                              : const Color(0xFF9D86CC),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha:0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MiniStat(
                        label: '本月',
                        value: '¥$monthValue',
                        sub: '${widget.monthSessions} 次',
                      ),
                      Container(
                          width: 1, height: 36, color: Colors.white12),
                      _MiniStat(
                        label: '今年已省',
                        value: '¥${widget.yearSessions * _price}',
                        sub: '${widget.yearSessions} 次',
                      ),
                      Container(
                          width: 1, height: 36, color: Colors.white12),
                      _MiniStat(
                        label: '回本倒计时',
                        value: countdownText(),
                        sub: totalValue >= _targetValue ? '🎉' : '坚持运动',
                      ),
                    ],
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

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(sub,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

// ── Weekly summary ─────────────────────────────────────────

class _WeeklySummaryCard extends StatelessWidget {
  final int weekCount;
  final int weekMins;
  final int todayCount;

  const _WeeklySummaryCard({
    required this.weekCount,
    required this.weekMins,
    required this.todayCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本周概览',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _WeeklyMetric(
                  emoji: '🎯',
                  value: '$weekCount',
                  label: '次训练',
                ),
              ),
              Expanded(
                child: _WeeklyMetric(
                  emoji: '⏱️',
                  value: '$weekMins',
                  label: '分钟',
                ),
              ),
              Expanded(
                child: _WeeklyMetric(
                  emoji: '📅',
                  value: '$todayCount',
                  label: '今日',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyMetric extends StatelessWidget {
  const _WeeklyMetric({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // 主插画区
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A2744).withValues(alpha:0.5)
                  : const Color(0xFFEBF2FF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha:0.15),
              ),
            ),
            child: Column(
              children: [
                // 动态图标组
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AnimIcon('🏊', const Color(0xFF00D4FF)),
                    const SizedBox(width: 20),
                    _AnimIcon('💪', const Color(0xFFFF6B35)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '开始记录你的运动之旅',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '每一次游泳、每一组训练\n都将成为你进步的见证',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 快捷引导卡片
          Row(
            children: [
              Expanded(
                child: _QuickStartCard(
                  emoji: '🏊',
                  title: '记录游泳',
                  subtitle: '距离 · 时长 · 泳姿',
                  color: const Color(0xFF00D4FF),
                  onTap: () {
                    // 触发底部导航跳转到游泳记录
                    // Navigator 会由 main_screen.dart 处理
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickStartCard(
                  emoji: '💪',
                  title: '记录健身',
                  subtitle: '动作 · 组数 · 重量',
                  color: const Color(0xFFFF6B35),
                  onTap: () {},
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 提示文字
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_downward_rounded,
                  size: 16,
                  color: theme.colorScheme.primary.withValues(alpha:0.6)),
              const SizedBox(width: 6),
              Text(
                '点击下方 ＋ 按钮开始',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary.withValues(alpha:0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimIcon extends StatelessWidget {
  final String emoji;
  final Color color;
  const _AnimIcon(this.emoji, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha:0.3), width: 2),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 36)),
      ),
    );
  }
}

class _QuickStartCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickStartCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha:0.1) : color.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha:0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  每日一句卡片
// ─────────────────────────────────────────────────────────
class _DailyQuoteCard extends StatelessWidget {
  const _DailyQuoteCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final quote = MotivationService.dailyQuote();

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? primary.withValues(alpha: 0.1)
              : primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            const Text('💬', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                quote,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? primary.withValues(alpha: 0.9)
                      : primary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
