import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class DesignPreviewScreen extends StatelessWidget {
  const DesignPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('FitFlow UI Preview'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '目标驱动版视觉预览',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '首页保持原有板块结构，只换视觉；成就页和身体指标页展示训练计划页风格的扩展方向。',
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.55,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Web 预览',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '下面是三个页面的静态视觉预览，不接真实数据，专门用来看风格方向。',
              style: TextStyle(color: Color(0xFF6B7280), height: 1.5),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _PhoneFrame(title: '首页', child: _HomePreview()),
                  SizedBox(width: 20),
                  _PhoneFrame(title: '我的', child: _ProfilePreview()),
                  SizedBox(width: 20),
                  _PhoneFrame(title: '成就页', child: _AchievementsPreview()),
                  SizedBox(width: 20),
                  _PhoneFrame(title: '身体指标页', child: _BodyMetricsPreview()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  final String title;
  final Widget child;

  const _PhoneFrame({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 110,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              color: const Color(0xFFF4F7FB),
              height: 780,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePreview extends StatelessWidget {
  const _HomePreview();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('下午好，保持状态', style: TextStyle(color: Color(0xFF6B7280))),
                    SizedBox(height: 4),
                    Text(
                      'Eden，今天继续推进目标',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172033),
                      ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFDCEAFE),
                child: Text('💪', style: TextStyle(fontSize: 24)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '2026年04月24日 星期五',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 18),
          Container(
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('本周概览', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _WeeklyMetric(emoji: '🏃', value: '3', label: '次运动')),
                    Expanded(child: _WeeklyMetric(emoji: '⏱️', value: '186', label: '分钟')),
                    Expanded(child: _WeeklyMetric(emoji: '📅', value: '1', label: '今日')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.1)),
            ),
            child: const Row(
              children: [
                Text('💬', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '先把今天能完成的那一节做掉，连续性会替你放大结果。',
                    style: TextStyle(
                      color: Color(0xFF4F46E5),
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A0A2E), Color(0xFF2D1654)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x334C1D95),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('💰', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 6),
                    Text(
                      '运动价值',
                      style: TextStyle(
                        color: Color(0xFFDDD6FE),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '¥40 / 次',
                      style: TextStyle(color: Color(0xFFFBBF24)),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  '¥4,800',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '累计 120 次运动，节省的健身费用',
                  style: TextStyle(color: Color(0xFF9D86CC)),
                ),
                SizedBox(height: 14),
                _ValueProgressCard(),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ValueMiniStat(
                        label: '本月',
                        value: '¥480',
                        sub: '12 次',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _ValueMiniStat(
                        label: '今年已省',
                        value: '¥1480',
                        sub: '37 次',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _ValueMiniStat(
                        label: '回本倒计时',
                        value: '187 次',
                        sub: '坚持运动',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SectionHeader(title: '最近记录', subtitle: '保留原有板块结构，只统一视觉样式'),
          const SizedBox(height: 12),
          ...const [
            _LogCard(type: '游泳', detail: '1500m · 42 分钟 · 技术课', date: '今天'),
            SizedBox(height: 10),
            _LogCard(type: '力量', detail: '全身训练 · 52 分钟 · 6 个动作', date: '昨天'),
            SizedBox(height: 10),
            _LogCard(type: '有氧', detail: '骑行 · 35 分钟 · 中低强度', date: '周一'),
          ],
        ],
      ),
    );
  }
}

class _WeeklyMetric extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _WeeklyMetric({
    required this.emoji,
    required this.value,
    required this.label,
  });

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
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

class _ValueProgressCard extends StatelessWidget {
  const _ValueProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '回本目标',
                style: TextStyle(color: Color(0xFFB9A7DA)),
              ),
              Spacer(),
              Text(
                '¥2520 / ¥10000',
                style: TextStyle(
                  color: Color(0xFFF3EDFF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: 0.252,
            minHeight: 8,
            borderRadius: BorderRadius.all(Radius.circular(999)),
            backgroundColor: Color(0x22FFFFFF),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
          ),
          SizedBox(height: 10),
          Text(
            '还差 ¥7480 达成目标',
            style: TextStyle(color: Color(0xFFB9A7DA)),
          ),
        ],
      ),
    );
  }
}

class _ValueMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _ValueMiniStat({
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB9A7DA),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              color: Color(0xFFB9A7DA),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AchievementsPreview extends StatelessWidget {
  const _AchievementsPreview();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('成就总览', style: TextStyle(color: Colors.white70)),
                    Spacer(),
                    Text('24 / 60', style: TextStyle(color: Colors.white)),
                  ],
                ),
                SizedBox(height: 14),
                Text(
                  '你已经完成 40%，下一批最容易解锁的是连续训练与月度挑战。',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 18),
                LinearProgressIndicator(
                  value: 0.4,
                  minHeight: 10,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                  backgroundColor: Color(0x33FFFFFF),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SectionHeader(title: '正在冲刺', subtitle: '突出接下来最容易拿下的成就'),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _AchievementFocusCard(
                  emoji: '🔥',
                  title: '连续 14 天',
                  progress: 0.86,
                  subtitle: '还差 2 天',
                  color: Color(0xFFEF4444),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _AchievementFocusCard(
                  emoji: '📅',
                  title: '本月 10 次训练',
                  progress: 0.7,
                  subtitle: '还差 3 次',
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionHeader(title: '分类墙', subtitle: '从纯宫格改成更有层次的收藏册'),
          const SizedBox(height: 12),
          const _AchievementShelf(title: '游泳', count: '6 / 12', items: ['🏊', '⚡', '🌊', '🫧']),
          const SizedBox(height: 12),
          const _AchievementShelf(title: '健身', count: '8 / 18', items: ['💪', '🏋️', '🎯', '🦾']),
          const SizedBox(height: 12),
          const _AchievementShelf(title: '连续性', count: '5 / 10', items: ['🔥', '📆', '⏱️', '🥇']),
        ],
      ),
    );
  }
}

class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0x33FFFFFF),
                      child: Text('💪', style: TextStyle(fontSize: 28)),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eden',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '持续运动第 128 天',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit_outlined, color: Colors.white),
                  ],
                ),
                SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _ProfileTopStat(value: '126', label: '累计训练')),
                    Expanded(child: _ProfileTopStat(value: '3120', label: '总分钟')),
                    Expanded(child: _ProfileTopStat(value: '12', label: '连续打卡')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SectionHeader(
            title: '个人中心',
            subtitle: '延续训练计划页的卡片和层级，但保留“我的”页面的信息分组',
          ),
          const SizedBox(height: 12),
          const _ProfileGroupCard(
            title: '概览',
            items: [
              _ProfileItemData(
                icon: Icons.assignment_outlined,
                color: Color(0xFF4F46E5),
                title: '训练计划',
                subtitle: '根据目标查看本周安排和今日建议',
              ),
              _ProfileItemData(
                icon: Icons.monitor_weight_outlined,
                color: Color(0xFF0EA5E9),
                title: '身体指标',
                subtitle: '体重、BMI、体脂率、肌肉含量等',
              ),
              _ProfileItemData(
                icon: Icons.emoji_events_outlined,
                color: Color(0xFFF59E0B),
                title: '我的成就',
                subtitle: '查看已解锁的成就和正在冲刺的目标',
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _ProfileGroupCard(
            title: '健身',
            items: [
              _ProfileItemData(
                icon: Icons.fitness_center_outlined,
                color: AppColors.gymAccent,
                title: '动作库',
                subtitle: '浏览所有健身动作，支持查看示范视频',
              ),
              _ProfileItemData(
                icon: Icons.water_outlined,
                color: AppColors.swimAccent,
                title: '月度报告',
                subtitle: '按月份查看游泳数据和里程碑',
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _ProfileGroupCard(
            title: '数据',
            items: [
              _ProfileItemData(
                icon: Icons.upload_outlined,
                color: Color(0xFF10B981),
                title: '导出数据',
                subtitle: '将所有运动记录导出为 JSON 文件',
              ),
              _ProfileItemData(
                icon: Icons.download_outlined,
                color: Color(0xFF8B5CF6),
                title: '导入数据',
                subtitle: '从 JSON 文件恢复运动记录',
              ),
              _ProfileItemData(
                icon: Icons.cloud_upload_outlined,
                color: Color(0xFF14B8A6),
                title: '同步到云端',
                subtitle: '将本地记录上传到 Supabase',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyMetricsPreview extends StatelessWidget {
  const _BodyMetricsPreview();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: '身体概况', subtitle: '保留原页面结构，只提升质感和层级'),
          const SizedBox(height: 18),
          const _BodyOverviewCard(),
          const SizedBox(height: 18),
          const _SectionHeader(title: '指标切换', subtitle: '沿用原交互，只把 chip 做得更轻更准'),
          const SizedBox(height: 12),
          const _MetricSelectorPreview(),
          const SizedBox(height: 18),
          const _SectionHeader(title: '趋势图', subtitle: '保留趋势图板块，改成更清爽的卡片和曲线表现'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '近 8 周体重趋势',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF172033),
                  ),
                ),
                SizedBox(height: 18),
                SizedBox(height: 170, child: _TrendCanvas()),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SectionHeader(title: '历史记录', subtitle: '保留列表结构，只统一卡片样式和信息层级'),
          const SizedBox(height: 12),
          ...const [
            _HistoryMetricCard(
              date: '2026/04/24',
              values: ['体重 64.2kg', 'BMI 22.4', '体脂 19.1%', '肌肉 27.8kg'],
            ),
            SizedBox(height: 10),
            _HistoryMetricCard(
              date: '2026/04/10',
              values: ['体重 65.0kg', 'BMI 22.7', '体脂 20.3%', '肌肉 27.7kg'],
            ),
            SizedBox(height: 10),
            _HistoryMetricCard(
              date: '2026/03/28',
              values: ['体重 65.4kg', 'BMI 22.9', '体脂 20.7%', '肌肉 27.6kg'],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF6B7280), height: 1.5),
        ),
      ],
    );
  }
}

class _LogCard extends StatelessWidget {
  final String type;
  final String detail;
  final String date;

  const _LogCard({
    required this.type,
    required this.detail,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                type == '游泳' ? '🏊' : type == '力量' ? '💪' : '🚴',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Text(date, style: const TextStyle(color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _AchievementFocusCard extends StatelessWidget {
  final String emoji;
  final String title;
  final double progress;
  final String subtitle;
  final Color color;

  const _AchievementFocusCard({
    required this.emoji,
    required this.title,
    required this.progress,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AchievementShelf extends StatelessWidget {
  final String title;
  final String count;
  final List<String> items;

  const _AchievementShelf({
    required this.title,
    required this.count,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              Text(count, style: const TextStyle(color: Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: items
                .map(
                  (item) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(item, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MetricStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final Color color;

  const _MetricStatCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF172033),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            delta,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyOverviewCard extends StatelessWidget {
  const _BodyOverviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              children: [
                SizedBox(height: 8),
                Text('🧍', style: TextStyle(fontSize: 96)),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TinyDot(active: true),
                    SizedBox(width: 8),
                    _TinyDot(active: false),
                  ],
                ),
                SizedBox(height: 6),
                Text('正面', style: TextStyle(color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: Column(
              children: [
                _MetricStatCard(label: '体重', value: '64.2kg', delta: '-0.8kg', color: Color(0xFF0EA5E9)),
                SizedBox(height: 10),
                _MetricStatCard(label: '身高', value: '169.0cm', delta: '已记录', color: Color(0xFF14B8A6)),
                SizedBox(height: 10),
                _MetricStatCard(label: 'BMI', value: '22.4', delta: '正常', color: Color(0xFF8B5CF6)),
                SizedBox(height: 10),
                _MetricStatCard(label: '体脂率', value: '19.1%', delta: '-1.2%', color: Color(0xFFF59E0B)),
                SizedBox(height: 10),
                _MetricStatCard(label: '肌肉量', value: '27.8kg', delta: '+0.1kg', color: Color(0xFF10B981)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyDot extends StatelessWidget {
  final bool active;

  const _TinyDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.gymAccent : const Color(0xFFD1D5DB),
      ),
    );
  }
}

class _MetricSelectorPreview extends StatelessWidget {
  const _MetricSelectorPreview();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _MetricChip(label: '体重', selected: true)),
        SizedBox(width: 8),
        Expanded(child: _MetricChip(label: 'BMI', selected: false)),
        SizedBox(width: 8),
        Expanded(child: _MetricChip(label: '体脂率', selected: false)),
        SizedBox(width: 8),
        Expanded(child: _MetricChip(label: '肌肉', selected: false)),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _MetricChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.gymAccent : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? AppColors.gymAccent
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF6B7280),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _HistoryMetricCard extends StatelessWidget {
  final String date;
  final List<String> values;

  const _HistoryMetricCard({
    required this.date,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: values
                      .map(
                        (item) => Text(
                          item,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Icon(Icons.edit_outlined, color: Colors.blue.shade300),
              const SizedBox(height: 10),
              Icon(Icons.delete_outline, color: Colors.red.shade300),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendCanvas extends StatelessWidget {
  const _TrendCanvas();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrendPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ProfileTopStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileTopStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ProfileGroupCard extends StatelessWidget {
  final String title;
  final List<_ProfileItemData> items;

  const _ProfileGroupCard({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 14),
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: _ProfileMenuTile(item: entry.value),
            );
          }),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final _ProfileItemData item;

  const _ProfileMenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}

class _ProfileItemData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _ProfileItemData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

class _TrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    final line = Paint()
      ..color = const Color(0xFF0EA5E9)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x330EA5E9), Color(0x000EA5E9)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);

    for (var i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final points = [
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.16, size.height * 0.68),
      Offset(size.width * 0.32, size.height * 0.63),
      Offset(size.width * 0.48, size.height * 0.56),
      Offset(size.width * 0.64, size.height * 0.5),
      Offset(size.width * 0.8, size.height * 0.42),
      Offset(size.width, size.height * 0.32),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final control = Offset((prev.dx + current.dx) / 2, prev.dy);
      path.quadraticBezierTo(control.dx, control.dy, current.dx, current.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, line);

    final dot = Paint()..color = const Color(0xFF0EA5E9);
    for (final point in points) {
      canvas.drawCircle(point, 4.5, dot);
      canvas.drawCircle(point, 8, Paint()..color = const Color(0x220EA5E9));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
