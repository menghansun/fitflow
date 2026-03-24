import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_session.dart';
import '../../providers/workout_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motivation_dialogs.dart';

class OtherActivityScreen extends StatefulWidget {
  final WorkoutSession? editSession;
  const OtherActivityScreen({super.key, this.editSession});

  @override
  State<OtherActivityScreen> createState() => _OtherActivityScreenState();
}

class _OtherActivityScreenState extends State<OtherActivityScreen> {
  final _labelController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;

  static const _accent = Color(0xFF9C6FDE); // 紫色区分其他类型

  @override
  void initState() {
    super.initState();
    final s = widget.editSession;
    if (s != null) {
      _labelController.text = s.notes ?? '';
      _notesController.text = '';
      _startDate = s.date;
      _endDate = s.endDate ?? s.date;
    } else {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = DateTime(now.year, now.month, now.day);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _save() async {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写活动名称')),
      );
      return;
    }

    final provider = context.read<WorkoutProvider>();
    final session = WorkoutSession(
      id: widget.editSession?.id ?? provider.generateId(),
      date: _startDate,
      endDate: _endDate,
      type: WorkoutType.other,
      durationSeconds: 0,
      notes: label,
    );

    await provider.addSession(session);
    if (!mounted) return;

    final days = _endDate.difference(_startDate).inDays + 1;
    final daysText = days == 1 ? '1 天' : '$days 天';

    await showSuccessDialog(
      context: context,
      typeKey: 'other',
      typeEmoji: '📌',
      typeLabel: label,
      detailText: '$label · $daysText',
      isEdit: widget.editSession != null,
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  bool get _isSingleDay =>
      _startDate.year == _endDate.year &&
      _startDate.month == _endDate.month &&
      _startDate.day == _endDate.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.editSession != null;
    final days = _endDate.difference(_startDate).inDays + 1;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // ── 渐变头部 ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor:
                isDark ? AppColors.darkBackground : AppColors.lightBackground,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: _save,
                child: Text(
                  isEdit ? '保存修改' : '保存',
                  style: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _accent.withValues(alpha:0.3),
                      _accent.withValues(alpha:0.05),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📌 其他活动',
                          style: theme.textTheme.headlineLarge
                              ?.copyWith(color: _accent),
                        ),
                        Text(
                          isEdit ? '编辑活动记录' : '记录生活中的其他事项',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 表单 ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 活动名称
                  Text('活动名称', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _labelController,
                    decoration: InputDecoration(
                      hintText: '例如：旅游、休息、出差…',
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: _accent, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 日期选择
                  Text('日期', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),

                  // 开始日期
                  _DateTile(
                    label: '开始',
                    date: _startDate,
                    accent: _accent,
                    isDark: isDark,
                    onTap: _pickStartDate,
                  ),
                  const SizedBox(height: 10),

                  // 结束日期
                  _DateTile(
                    label: '结束',
                    date: _endDate,
                    accent: _accent,
                    isDark: isDark,
                    onTap: _pickEndDate,
                  ),

                  // 跨天提示
                  if (!_isSingleDay) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha:0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: _accent),
                          const SizedBox(width: 8),
                          Text(
                            '共 $days 天，将在日历上每天都显示',
                            style: const TextStyle(
                                fontSize: 13, color: _accent),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // 保存按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        isEdit ? '保存修改' : '保存记录',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.date,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text =
        '${date.year}年${date.month.toString().padLeft(2, '0')}月${date.day.toString().padLeft(2, '0')}日';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent),
              ),
            ),
            const SizedBox(width: 12),
            Text(text,
                style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            Icon(Icons.chevron_right,
                size: 18,
                color: Theme.of(context).textTheme.bodyMedium?.color),
          ],
        ),
      ),
    );
  }
}
