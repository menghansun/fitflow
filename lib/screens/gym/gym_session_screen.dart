import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_session.dart';
import '../../providers/workout_provider.dart';
import '../../services/exercise_library.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../services/exercise_gif_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motivation_dialogs.dart';

// ─────────────────────────────────────────────────────────
//  健身记录主屏幕
// ─────────────────────────────────────────────────────────
class GymSessionScreen extends StatefulWidget {
  final WorkoutSession? editSession;
  final DateTime? initialDate;
  const GymSessionScreen({super.key, this.editSession, this.initialDate});

  @override
  State<GymSessionScreen> createState() => _GymSessionScreenState();
}

class _GymSessionScreenState extends State<GymSessionScreen> {
  // ── 时长 ───────────────────────────────────────────────
  int _durHours = 1;
  int _durMinutes = 0;

  // ── 练习列表 ───────────────────────────────────────────
  final List<_ExerciseEntry> _exercises = [];

  // ── 卡路里 ─────────────────────────────────────────────
  final _caloriesController = TextEditingController();
  late DateTime _sessionDate;

  // ── 防重复点击 ─────────────────────────────────────────
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.editSession;
    _sessionDate = s?.date ?? widget.initialDate ?? DateTime.now();
    if (s != null) {
      final total = s.durationSeconds;
      _durHours = total ~/ 3600;
      _durMinutes = (total % 3600) ~/ 60;
      if (s.calories != null) {
        _caloriesController.text = '${s.calories}';
      }
      if (s.exercises != null) {
        for (final ex in s.exercises!) {
          _exercises.add(_ExerciseEntry(
            name: ex.name,
            muscleGroup: ex.muscleGroup,
            sets: ex.sets
                .map((gs) => _SetData(
                      reps: gs.reps,
                      weight: gs.weight,
                      durationSeconds: gs.durationSeconds,
                      isBodyweight: gs.isBodyweight,
                      completed: true,
                    ))
                .toList(),
          ));
        }
      }
    }
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _pickSessionDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;
    setState(() {
      _sessionDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _sessionDate.hour,
        _sessionDate.minute,
      );
    });
  }

  Future<void> _pickSessionTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_sessionDate),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _sessionDate = DateTime(
        _sessionDate.year,
        _sessionDate.month,
        _sessionDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  // ── 添加练习 ───────────────────────────────────────────
  void _showAddExercise() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExercisePickerSheet(
        onSelected: (name, group) {
          setState(() {
            _exercises.add(_ExerciseEntry(name: name, muscleGroup: group));
          });
        },
      ),
    );
  }

  // ── 结束训练 ───────────────────────────────────────────
  Future<void> _finish() async {
    if (_isSaving) return;
    _isSaving = true;
    try {
      final totalSecs = _durHours * 3600 + _durMinutes * 60;

      final exercises = _exercises
          .where((e) => e.sets.isNotEmpty)
          .map((e) => GymExercise(
                name: e.name,
                muscleGroup: e.muscleGroup,
                sets: e.sets
                    .map((s) => GymSet(
                          reps: s.reps,
                          weight: s.weight,
                          durationSeconds: s.durationSeconds,
                          isBodyweight: s.isBodyweight,
                        ))
                    .toList(),
              ))
          .toList();

      final totalSets = exercises.fold(0, (s, e) => s + e.sets.length);

      final cals = int.tryParse(_caloriesController.text.trim());

      final session = WorkoutSession(
        id: widget.editSession?.id ?? context.read<WorkoutProvider>().generateId(),
        date: _sessionDate,
        type: WorkoutType.gym,
        durationSeconds: totalSecs,
        exercises: exercises.isNotEmpty ? exercises : null,
        calories: cals,
      );

      await context.read<WorkoutProvider>().addSession(session);
      if (!mounted) return;

      if (widget.editSession != null) {
        Navigator.pop(context, true);
        return;
      }
      await _showSummary(session, totalSets);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showSummary(WorkoutSession s, int totalSets) async {
    final h = s.durationSeconds ~/ 3600;
    final m = (s.durationSeconds % 3600) ~/ 60;
    final dur = h > 0 ? '$h时${m.toString().padLeft(2, '0')}分' : '$m分';
    final detail = '$dur · ${s.exercises?.length ?? 0} 个动作 · $totalSets 组';

    await showSuccessDialog(
      context: context,
      typeKey: 'gym',
      typeEmoji: '🏋️',
      typeLabel: '健身',
      detailText: detail,
      isEdit: false,
    );
    if (!mounted) return;
    // 里程碑检查
    final streak = context.read<WorkoutProvider>().currentStreak;
    await checkAndShowMilestone(context, streak);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _pickDateTime() async {
    await _pickSessionDate();
    if (mounted) await _pickSessionTime();
  }

  Widget _sectionLabel(String text, ThemeData theme) =>
      Text(text, style: theme.textTheme.titleMedium);

  // ── Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppColors.gymAccent;
    final isEdit = widget.editSession != null;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // ── 渐变头部 ─────────────────────────────────
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
                onPressed: _isSaving ? null : _finish,
                child: Text(
                  _isSaving ? '保存中...' : (isEdit ? '保存修改' : '保存'),
                  style: TextStyle(
                      color: _isSaving ? Colors.grey : accent,
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
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🏋️ 健身',
                          style: theme.textTheme.headlineLarge
                              ?.copyWith(color: accent),
                        ),
                        Text(
                          isEdit ? '编辑健身记录' : '记录健身训练',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 表单区域 ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日期
                  _sectionLabel('日期 / 时间', theme),
                  const SizedBox(height: 10),
                  _GymDateTile(
                    date: _sessionDate,
                    accent: accent,
                    isDark: isDark,
                    onTap: _pickDateTime,
                  ),
                  const SizedBox(height: 24),

                  // 时长
                  _sectionLabel('时长', theme),
                  const SizedBox(height: 10),
                  _GymDurationPicker(
                    hours: _durHours,
                    minutes: _durMinutes,
                    accent: accent,
                    isDark: isDark,
                    onChanged: (h, m) => setState(() {
                      _durHours = h;
                      _durMinutes = m;
                    }),
                  ),
                  const SizedBox(height: 24),

                  // 卡路里
                  _sectionLabel('卡路里（可选）', theme),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '本次消耗热量',
                      suffixText: 'kcal',
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 训练动作标题
                  _sectionLabel('训练动作', theme),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // ── 练习列表 ──────────────────────────────────
          if (_exercises.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: _EmptyExerciseState(onAdd: _showAddExercise),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = _exercises[index];
                    return _ExerciseCard(
                      entry: entry,
                      index: index,
                      onDelete: () =>
                          setState(() => _exercises.removeAt(index)),
                      onSetComplete: (_) {},
                      onChanged: () => setState(() {}),
                    );
                  },
                  childCount: _exercises.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: _AddExerciseButton(onTap: _showAddExercise),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  日期时间 Tile
// ─────────────────────────────────────────────────────────
class _GymDateTile extends StatelessWidget {
  final DateTime date;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _GymDateTile({
    required this.date,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text =
        '${date.year}年${date.month.toString().padLeft(2, '0')}月'
        '${date.day.toString().padLeft(2, '0')}日  '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

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
            Icon(Icons.calendar_today_outlined, size: 18, color: accent),
            const SizedBox(width: 10),
            Text(text, style: theme.textTheme.bodyLarge),
            const Spacer(),
            Icon(Icons.chevron_right,
                size: 18,
                color: theme.textTheme.bodyMedium?.color),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  时长滚轮选择器（时 / 分）
// ─────────────────────────────────────────────────────────
class _GymDurationPicker extends StatelessWidget {
  final int hours;
  final int minutes;
  final Color accent;
  final bool isDark;
  final void Function(int h, int m) onChanged;

  const _GymDurationPicker({
    required this.hours,
    required this.minutes,
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
          _wheel('时', hours, 24, (v) => onChanged(v, minutes)),
          _divider(),
          _wheel('分', minutes, 60, (v) => onChanged(hours, v)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 20),
        color: Colors.grey.withValues(alpha:0.2),
      );

  Widget _wheel(String unit, int value, int count,
      ValueChanged<int> onSelectedItemChanged) {
    return Expanded(
      child: Column(
        children: [
          const SizedBox(height: 6),
          Text(unit,
              style: TextStyle(color: accent, fontSize: 12)),
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
//  练习卡片
// ─────────────────────────────────────────────────────────
class _ExerciseCard extends StatelessWidget {
  final _ExerciseEntry entry;
  final int index;
  final VoidCallback onDelete;
  final ValueChanged<int> onSetComplete;
  final VoidCallback onChanged;

  const _ExerciseCard({
    required this.entry,
    required this.index,
    required this.onDelete,
    required this.onSetComplete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final sectionBg = isDark ? const Color(0xFF1A2035) : const Color(0xFFF6F8FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.gymAccent.withValues(alpha:0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gymAccent.withValues(alpha:isDark ? 0.08 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
            child: Row(
              children: [
                // Thumbnail
                Builder(builder: (ctx) {
                  final assetPath = ExerciseGifService.assetPath(entry.name);
                  if (assetPath == null) {
                    return Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.gymAccent.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(entry.muscleGroup.emoji,
                            style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () => showDialog(
                      context: ctx,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(assetPath,
                                  width: double.infinity, fit: BoxFit.contain),
                            ),
                            const SizedBox(height: 12),
                            Text(entry.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('关闭',
                                  style: TextStyle(color: Colors.white70)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(assetPath,
                          width: 48, height: 48, fit: BoxFit.cover),
                    ),
                  );
                }),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gymAccent.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${entry.muscleGroup.emoji} ${entry.muscleGroup.displayName}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gymAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: Colors.red.shade300,
                  onPressed: onDelete,
                  padding: const EdgeInsets.all(8),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),

          // ── Set section ──────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            decoration: BoxDecoration(
              color: sectionBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Column header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text('组',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha:0.5))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('次数',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha:0.5))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('重量 (kg)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha:0.5))),
                      ),
                      const SizedBox(width: 52),
                    ],
                  ),
                ),

                // Set rows
                ...entry.sets.asMap().entries.map((e) => _SetRow(
                      setNumber: e.key + 1,
                      setData: e.value,
                      isDark: isDark,
                      onComplete: () => onSetComplete(e.key),
                      onChanged: onChanged,
                      onDelete: () {
                        entry.sets.removeAt(e.key);
                        onChanged();
                      },
                    )),

                // Add set button
                GestureDetector(
                  onTap: () {
                    final last =
                        entry.sets.isNotEmpty ? entry.sets.last : null;
                    entry.sets.add(_SetData(
                      reps: last?.reps ?? 12,
                      weight: last?.weight ?? 0,
                      isBodyweight: last?.isBodyweight ?? false,
                    ));
                    onChanged();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.gymAccent.withValues(alpha:0.12),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 15,
                            color: AppColors.gymAccent.withValues(alpha:0.8)),
                        const SizedBox(width: 5),
                        Text(
                          '添加一组',
                          style: TextStyle(
                            color: AppColors.gymAccent.withValues(alpha:0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
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

class _SetRow extends StatefulWidget {
  final int setNumber;
  final _SetData setData;
  final bool isDark;
  final VoidCallback onComplete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _SetRow({
    required this.setNumber,
    required this.setData,
    required this.isDark,
    required this.onComplete,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _repsCtrl;
  late TextEditingController _weightCtrl;

  @override
  void initState() {
    super.initState();
    _repsCtrl = TextEditingController(text: '${widget.setData.reps}');
    _weightCtrl = widget.setData.isBodyweight
        ? TextEditingController(text: '自重')
        : TextEditingController(
            text: widget.setData.weight == 0
                ? ''
                : '${widget.setData.weight}');
  }

  @override
  void dispose() {
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.setData.completed;
    final inputBg = completed
        ? Colors.green.withValues(alpha:0.1)
        : (widget.isDark ? const Color(0xFF252D40) : Colors.white);
    final inputBorder = completed
        ? Colors.green.withValues(alpha:0.3)
        : Colors.transparent;

    InputDecoration inputDec(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.grey.withValues(alpha:0.4), fontSize: 13),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          isDense: true,
          filled: true,
          fillColor: inputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
                color: AppColors.gymAccent, width: 1.5),
          ),
        );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
      decoration: BoxDecoration(
        color: completed
            ? Colors.green.withValues(alpha:0.04)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Set number
          SizedBox(
            width: 28,
            child: Text(
              '${widget.setNumber}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: completed
                    ? Colors.green.shade400
                    : AppColors.gymAccent,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Reps
          Expanded(
            child: TextField(
              controller: _repsCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: completed ? Colors.green.shade400 : null,
              ),
              decoration: inputDec('10'),
              onChanged: (v) {
                widget.setData.reps = int.tryParse(v) ?? 0;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),

          // Weight
          Expanded(
            child: TextField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: completed ? Colors.green.shade400 : null,
              ),
              decoration: inputDec('kg'),
              onChanged: (v) {
                if (v == '自重' || v.toLowerCase() == 'bw') {
                  widget.setData.isBodyweight = true;
                  widget.setData.weight = 0;
                } else {
                  widget.setData.isBodyweight = false;
                  widget.setData.weight = double.tryParse(v) ?? 0;
                }
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 6),

          // Actions
          SizedBox(
            width: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() =>
                        widget.setData.completed = !completed);
                    if (!completed) widget.onComplete();
                    widget.onChanged();
                  },
                  child: Icon(
                    completed
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    size: 24,
                    color: completed
                        ? Colors.green.shade400
                        : Colors.grey.withValues(alpha:0.4),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(Icons.close,
                      size: 16,
                      color: Colors.grey.withValues(alpha:0.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  动作选择 Sheet
// ─────────────────────────────────────────────────────────
class _ExercisePickerSheet extends StatefulWidget {
  final void Function(String name, MuscleGroup group) onSelected;

  const _ExercisePickerSheet({required this.onSelected});

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  MuscleGroup _selectedGroup = MuscleGroup.chest;
  final TextEditingController _customCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _customCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showExerciseDetail(
      BuildContext context, ExerciseMeta meta, bool isDark, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 拖拽条
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  // ── 视频占位 ──────────────────────────
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A2035)
                          : const Color(0xFFF0F2F8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gymAccent.withValues(alpha:0.2),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: meta.videoUrl != null && meta.videoUrl!.isNotEmpty
                        ? _VideoPlayerWidget(videoUrl: meta.videoUrl!)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                size: 52,
                                color: AppColors.gymAccent.withValues(alpha:0.5),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '示范视频',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gymAccent.withValues(alpha:0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '即将上线',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.withValues(alpha:0.5),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),

                  // 标题 + 标签
                  Text(meta.name,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PickerTag(meta.difficulty, const Color(0xFF3D7BF6), Colors.white),
                      _PickerTag(meta.equipment, Colors.grey.shade100, const Color(0xFF475467)),
                      _PickerTag(meta.category, const Color(0xFFEAFBF0), const Color(0xFF1E9D57)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 目标肌群
                  _DetailSection(
                    title: '目标肌群',
                    isDark: isDark,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: meta.targetMuscles
                          .map((m) => _PickerTag(
                              m, const Color(0xFFFFF1F1), const Color(0xFFD92D20)))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 动作要领
                  _DetailSection(
                    title: '动作要领',
                    isDark: isDark,
                    child: Column(
                      children: meta.cues.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22, height: 22,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                  color: Color(0xFFEAF0FF), shape: BoxShape.circle),
                              child: Text('${e.key + 1}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.gymAccent)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(e.value,
                                    style: const TextStyle(height: 1.5))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 注意事项
                  _DetailSection(
                    title: '注意事项',
                    isDark: isDark,
                    child: Column(
                      children: meta.tips.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Icon(Icons.circle, size: 5, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(t, style: const TextStyle(height: 1.5))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 添加按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // 关闭详情
                        widget.onSelected(meta.name, meta.group);
                        Navigator.pop(context); // 关闭选择 Sheet
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('添加到训练'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gymAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final exercises = _query.isEmpty
        ? ExerciseLibrary.getMetasForGroup(_selectedGroup)
        : ExerciseLibrary.search(_query);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha:0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('选择动作',
                    style: theme.textTheme.headlineMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: '搜索练习',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    fillColor: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                    filled: true,
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                // Muscle group chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: MuscleGroup.values.map((g) {
                      final sel = _selectedGroup == g;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedGroup = g),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.gymAccent
                                      .withValues(alpha:0.2)
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                color: sel
                                    ? AppColors.gymAccent
                                    : Colors.grey.withValues(alpha:0.4),
                                width: sel ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              '${g.emoji} ${g.displayName}',
                              style: TextStyle(
                                color: sel
                                    ? AppColors.gymAccent
                                    : theme
                                        .textTheme.bodyMedium
                                        ?.color,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // Exercise list
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(24, 0, 24, 16),
              children: [
                ...exercises.map((meta) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showExerciseDetail(context, meta, isDark, theme),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.gymAccent.withValues(alpha:0.12)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(meta.name,
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      widget.onSelected(meta.name, meta.group);
                                      Navigator.pop(context);
                                    },
                                    child: const Icon(Icons.add_circle_outline, color: AppColors.gymAccent),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 84,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: AppColors.gymAccent.withValues(alpha:0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: meta.imageAsset.isNotEmpty
                                        ? Image.asset(meta.imageAsset, fit: BoxFit.cover)
                                        : const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.image_outlined, color: AppColors.gymAccent),
                                              SizedBox(height: 4),
                                              Text('动作图', style: TextStyle(fontSize: 11, color: AppColors.gymAccent)),
                                            ],
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _PickerTag(meta.difficulty, const Color(0xFF3D7BF6), Colors.white),
                                        _PickerTag(meta.equipment, Colors.grey.shade100, const Color(0xFF475467)),
                                        _PickerTag(meta.category, const Color(0xFFEAFBF0), const Color(0xFF1E9D57)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 64,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha:0.06),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(meta.group.emoji, style: const TextStyle(fontSize: 20)),
                                        const SizedBox(height: 4),
                                        const Icon(Icons.accessibility_new, size: 18, color: Color(0xFFEF4444)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                // Custom exercise input
                const Divider(height: 24),
                Text('自定义动作',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customCtrl,
                        decoration: const InputDecoration(
                          hintText: '输入自定义动作名称',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final name = _customCtrl.text.trim();
                        if (name.isEmpty) return;
                        widget.onSelected(name, _selectedGroup);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gymAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14)),
                      child: const Text('添加'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  辅助 widgets / data classes
// ─────────────────────────────────────────────────────────
class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;
  const _DetailSection({required this.title, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PickerTag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _PickerTag(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyExerciseState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyExerciseState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏋️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('还没有动作', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('点击下方按钮添加训练动作',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('添加动作'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gymAccent),
          ),
        ],
      ),
    );
  }
}

class _AddExerciseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddExerciseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.gymAccent.withValues(alpha:0.4),
            width: 1.5,
            // Dashed border achieved via a CustomPainter is complex, so we
            // use a low-opacity solid border with no fill for a minimal look.
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                color: AppColors.gymAccent, size: 20),
            SizedBox(width: 8),
            Text(
              '添加动作',
              style: TextStyle(
                color: AppColors.gymAccent,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Local data models (not persisted directly)
// ─────────────────────────────────────────────────────────
class _ExerciseEntry {
  final String name;
  MuscleGroup muscleGroup;
  final List<_SetData> sets;

  _ExerciseEntry({
    required this.name,
    required this.muscleGroup,
    List<_SetData>? sets,
  }) : sets = sets ??
            [_SetData(reps: 10, weight: 0)]; // start with one empty set
}

class _SetData {
  int reps;
  double weight;
  int durationSeconds;
  bool isBodyweight;
  bool completed;

  _SetData({
    this.reps = 10,
    this.weight = 0,
    this.durationSeconds = 0,
    this.isBodyweight = false,
    this.completed = false,
  });
  }


class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerWidget({required this.videoUrl});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer(widget.videoUrl);
  }

  Future<void> _initPlayer(String url) async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await _controller!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: false,
        looping: false,
        aspectRatio: _controller!.value.aspectRatio,
        errorBuilder: (ctx, err) => Center(
          child: Text('视频加载失败', style: TextStyle(color: Colors.red[700])),
        ),
      );
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('视频加载失败', style: TextStyle(color: Colors.red[700])));
    }
    return Chewie(controller: _chewieController!);
  }
}

