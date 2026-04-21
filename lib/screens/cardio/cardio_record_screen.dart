import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_session.dart';
import '../../providers/workout_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motivation_dialogs.dart';

// ─────────────────────────────────────────────────────────
//  有氧运动子类型
// ─────────────────────────────────────────────────────────
enum _CardioType {
  running('running', '🏃', '跑步'),
  other('other', '❤️', '其它');

  const _CardioType(this.key, this.emoji, this.label);
  final String key;
  final String emoji;
  final String label;
}

// ─────────────────────────────────────────────────────────
//  有氧运动记录页
// ─────────────────────────────────────────────────────────
class CardioRecordScreen extends StatefulWidget {
  final WorkoutSession? editSession;
  final DateTime? initialDate;
  const CardioRecordScreen({super.key, this.editSession, this.initialDate});

  @override
  State<CardioRecordScreen> createState() => _CardioRecordScreenState();
}

class _CardioRecordScreenState extends State<CardioRecordScreen> {
  _CardioType _cardioType = _CardioType.running;
  final _customTypeController = TextEditingController();

  late DateTime _date;

  // 时长
  int _durHours = 0;
  int _durMinutes = 30;
  int _durSecs = 0;

  // 距离 (km, supports 1 decimal)
  final _distanceController = TextEditingController();

  // 心率
  bool _showHeartRate = false;
  final _hrAvgController = TextEditingController();
  final _hrMaxController = TextEditingController();

  // 卡路里
  bool _showCalories = false;
  final _caloriesController = TextEditingController();

  // 备注
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = widget.editSession;
    if (s != null) {
      _date = s.date;
      final totalSecs = s.durationSeconds;
      _durHours = totalSecs ~/ 3600;
      _durMinutes = (totalSecs % 3600) ~/ 60;
      _durSecs = totalSecs % 60;

      if (s.totalDistanceMeters != null) {
        _distanceController.text =
            (s.totalDistanceMeters! / 1000.0).toStringAsFixed(1);
      }
      if (s.heartRateAvg != null) {
        _showHeartRate = true;
        _hrAvgController.text = '${s.heartRateAvg}';
      }
      if (s.heartRateMax != null) {
        _showHeartRate = true;
        _hrMaxController.text = '${s.heartRateMax}';
      }
      if (s.calories != null) {
        _showCalories = true;
        _caloriesController.text = '${s.calories}';
      }
      if (s.notes != null) {
        _notesController.text = s.notes!;
      }
      if (s.cardioType != null) {
        if (s.cardioType == 'running') {
          _cardioType = _CardioType.running;
        } else {
          _cardioType = _CardioType.other;
          _customTypeController.text = s.cardioType!;
        }
      }
    } else {
      _date = widget.initialDate ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _customTypeController.dispose();
    _distanceController.dispose();
    _hrAvgController.dispose();
    _hrMaxController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_date),
      );
      if (time != null) {
        setState(() {
          _date = DateTime(
              picked.year, picked.month, picked.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _save() async {
    final totalSecs = _durHours * 3600 + _durMinutes * 60 + _durSecs;
    if (totalSecs == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入运动时长')),
      );
      return;
    }

    final distText = _distanceController.text.trim();
    int? distMeters;
    if (distText.isNotEmpty) {
      final km = double.tryParse(distText);
      if (km == null || km < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('距离格式不正确')),
        );
        return;
      }
      distMeters = (km * 1000).round();
    }

    final hrAvg = int.tryParse(_hrAvgController.text.trim());
    final hrMax = int.tryParse(_hrMaxController.text.trim());
    final cals = int.tryParse(_caloriesController.text.trim());
    final notes = _notesController.text.trim();

    final provider = context.read<WorkoutProvider>();

    final session = WorkoutSession(
      id: widget.editSession?.id ?? provider.generateId(),
      date: _date,
      type: WorkoutType.cardio,
      durationSeconds: totalSecs,
      totalDistanceMeters: distMeters,
      heartRateAvg: _showHeartRate ? hrAvg : null,
      heartRateMax: _showHeartRate ? hrMax : null,
      calories: _showCalories ? cals : null,
      notes: notes.isEmpty ? null : notes,
      cardioType: _cardioType == _CardioType.other
          ? (_customTypeController.text.trim().isNotEmpty
              ? _customTypeController.text.trim()
              : '其它')
          : _cardioType.key,
    );

    await provider.addSession(session);
    if (!mounted) return;

    final totalMins = (_durHours * 3600 + _durMinutes * 60 + _durSecs) ~/ 60;
    final savedDistText = _distanceController.text.trim();
    final distDisplay = savedDistText.isNotEmpty ? ' · $savedDistText km' : '';

    final customName = _cardioType == _CardioType.other
        ? (_customTypeController.text.trim().isNotEmpty
            ? _customTypeController.text.trim()
            : '其它')
        : _cardioType.label;
    await showSuccessDialog(
      context: context,
      typeKey: _cardioType.key,
      typeEmoji: _cardioType.emoji,
      typeLabel: customName,
      detailText: '$customName  $totalMins 分钟$distDisplay',
      isEdit: widget.editSession != null,
    );
    if (!mounted) return;
    // 里程碑检查
    final streak = context.read<WorkoutProvider>().currentStreak;
    await checkAndShowMilestone(context, streak);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppColors.cardioAccent;
    final isEdit = widget.editSession != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── 顶部渐变 Header ───────────────────────────────
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
                  '保存',
                  style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
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
                      accent.withValues(alpha:0.3),
                      accent.withValues(alpha:0.05),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_cardioType.emoji} ${_cardioType.label}',
                          style: theme.textTheme.headlineLarge
                              ?.copyWith(color: accent),
                        ),
                        Text(
                          isEdit ? '编辑有氧运动记录' : '记录有氧运动',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 表单内容 ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 子类型选择
                  _sectionLabel('运动类型', theme),
                  const SizedBox(height: 10),
                  _CardioTypeSelector(
                    selected: _cardioType,
                    accent: accent,
                    customController: _customTypeController,
                    onChanged: (t) => setState(() => _cardioType = t),
                  ),

                  const SizedBox(height: 24),

                  // 日期时间
                  _sectionLabel('日期 / 时间', theme),
                  const SizedBox(height: 10),
                  _DateTimeTile(
                    date: _date,
                    accent: accent,
                    onTap: _pickDate,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 24),

                  // 时长
                  _sectionLabel('时长（必填）', theme),
                  const SizedBox(height: 10),
                  _DurationPicker(
                    hours: _durHours,
                    minutes: _durMinutes,
                    seconds: _durSecs,
                    accent: accent,
                    isDark: isDark,
                    onChanged: (h, m, s) => setState(() {
                      _durHours = h;
                      _durMinutes = m;
                      _durSecs = s;
                    }),
                  ),

                  const SizedBox(height: 24),

                  // 距离
                  _sectionLabel('距离（km，可选）', theme),
                  const SizedBox(height: 10),
                  _inputField(
                    controller: _distanceController,
                    hint: '例如 5.0',
                    suffix: 'km',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    accent: accent,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 24),

                  // 心率
                  _ToggleSection(
                    title: '心率',
                    enabled: _showHeartRate,
                    accent: accent,
                    isDark: isDark,
                    onToggle: (v) => setState(() => _showHeartRate = v),
                    child: Row(
                      children: [
                        Expanded(
                          child: _inputField(
                            controller: _hrAvgController,
                            hint: '均值',
                            suffix: 'bpm',
                            keyboardType: TextInputType.number,
                            accent: accent,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _inputField(
                            controller: _hrMaxController,
                            hint: '最大',
                            suffix: 'bpm',
                            keyboardType: TextInputType.number,
                            accent: accent,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 卡路里
                  _ToggleSection(
                    title: '卡路里',
                    enabled: _showCalories,
                    accent: accent,
                    isDark: isDark,
                    onToggle: (v) => setState(() => _showCalories = v),
                    child: _inputField(
                      controller: _caloriesController,
                      hint: '消耗热量',
                      suffix: 'kcal',
                      keyboardType: TextInputType.number,
                      accent: accent,
                      isDark: isDark,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 备注
                  _sectionLabel('备注（可选）', theme),
                  const SizedBox(height: 10),
                  _inputField(
                    controller: _notesController,
                    hint: '添加备注…',
                    maxLines: 3,
                    accent: accent,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 40),

                  // 保存按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _save,
                      child:
                          Text(isEdit ? '保存修改' : '保存记录',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
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

  Widget _sectionLabel(String text, ThemeData theme) {
    return Text(text, style: theme.textTheme.titleMedium);
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    String? suffix,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required Color accent,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  子类型 Chip 选择器
// ─────────────────────────────────────────────────────────
class _CardioTypeSelector extends StatelessWidget {
  final _CardioType selected;
  final Color accent;
  final TextEditingController customController;
  final ValueChanged<_CardioType> onChanged;

  const _CardioTypeSelector({
    required this.selected,
    required this.accent,
    required this.customController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _CardioType.values.map((t) {
        final isSelected = t == selected;
        final isOther = t == _CardioType.other;
        final isOtherSelected = isOther && isSelected;

        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => onChanged(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha:0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? accent
                      : Colors.grey.withValues(alpha:isOther ? 0.25 : 0.35),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    t.emoji,
                    style: TextStyle(
                      fontSize: 16,
                      color: isOther && !isSelected
                          ? const Color(0xFFBDBDBD)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isOtherSelected)
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: customController,
                        autofocus: true,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: accent,
                          height: 1.2,
                        ),
                        decoration: InputDecoration(
                          hintText: '运动名称',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: accent.withValues(alpha:0.35),
                          ),
                          isDense: true,
                          isCollapsed: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(bottom: 1),
                        ),
                      ),
                    )
                  else
                    Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: isOther
                            ? const Color(0xFFBDBDBD)
                            : isSelected
                                ? accent
                                : null,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  日期时间 Tile
// ─────────────────────────────────────────────────────────
class _DateTimeTile extends StatelessWidget {
  final DateTime date;
  final Color accent;
  final VoidCallback onTap;
  final bool isDark;

  const _DateTimeTile({
    required this.date,
    required this.accent,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text =
        '${date.year}年${date.month.toString().padLeft(2, '0')}月${date.day.toString().padLeft(2, '0')}日  '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: accent),
            const SizedBox(width: 10),
            Text(text, style: theme.textTheme.bodyLarge),
            const Spacer(),
            Icon(Icons.chevron_right, size: 18,
                color: theme.textTheme.bodyMedium?.color),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  时长 Picker（时 / 分 / 秒）
// ─────────────────────────────────────────────────────────
class _DurationPicker extends StatelessWidget {
  final int hours;
  final int minutes;
  final int seconds;
  final Color accent;
  final bool isDark;
  final void Function(int h, int m, int s) onChanged;

  const _DurationPicker({
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.accent,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _wheel('时', hours, 24, accent,
              (v) => onChanged(v, minutes, seconds)),
          _divider(),
          _wheel('分', minutes, 60, accent,
              (v) => onChanged(hours, v, seconds)),
          _divider(),
          _wheel('秒', seconds, 60, accent,
              (v) => onChanged(hours, minutes, v)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 20),
        color: Colors.grey.withValues(alpha:0.2),
      );

  Widget _wheel(String unit, int value, int count, Color accent,
      ValueChanged<int> onSelectedItemChanged) {
    return Expanded(
      child: Column(
        children: [
          const SizedBox(height: 6),
          Text(unit, style: TextStyle(color: accent, fontSize: 12)),
          Expanded(
            child: CupertinoPicker(
              scrollController:
                  FixedExtentScrollController(initialItem: value),
              itemExtent: 36,
              onSelectedItemChanged: onSelectedItemChanged,
              children: List.generate(
                count,
                (i) => Center(
                  child: Text(
                    i.toString().padLeft(2, '0'),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  可折叠 Toggle Section
// ─────────────────────────────────────────────────────────
class _ToggleSection extends StatelessWidget {
  final String title;
  final bool enabled;
  final Color accent;
  final bool isDark;
  final ValueChanged<bool> onToggle;
  final Widget child;

  const _ToggleSection({
    required this.title,
    required this.enabled,
    required this.accent,
    required this.isDark,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const Spacer(),
            Switch(
              value: enabled,
              onChanged: onToggle,
              activeTrackColor: accent,
            ),
          ],
        ),
        if (enabled) ...[
          const SizedBox(height: 10),
          child,
        ],
      ],
    );
  }
}
