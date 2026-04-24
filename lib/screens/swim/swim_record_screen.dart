import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_session.dart';
import '../../providers/workout_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/ocr_service.dart';
import '../../widgets/motivation_dialogs.dart';

String _styleLabel(SwimStyle style) {
  switch (style) {
    case SwimStyle.freestyle:
      return '自由泳';
    case SwimStyle.breaststroke:
      return '蛙泳';
    case SwimStyle.backstroke:
      return '仰泳';
    case SwimStyle.butterfly:
      return '蝶泳';
    case SwimStyle.medley:
      return '混合泳';
  }
}

String _styleEmoji(SwimStyle style) {
  switch (style) {
    case SwimStyle.freestyle:
      return '🏊';
    case SwimStyle.breaststroke:
      return '🐸';
    case SwimStyle.backstroke:
      return '🔄';
    case SwimStyle.butterfly:
      return '🦋';
    case SwimStyle.medley:
      return '🏅';
  }
}

class SwimRecordScreen extends StatefulWidget {
  final WorkoutSession? editSession;
  final DateTime? initialDate;
  const SwimRecordScreen({super.key, this.editSession, this.initialDate});

  @override
  State<SwimRecordScreen> createState() => _SwimRecordScreenState();
}

class _SwimRecordScreenState extends State<SwimRecordScreen> {
  late DateTime _date;

  // OCR 服务
  final _ocrService = HuaweiHealthOcrService();
  bool _ocrLoading = false;

  int _durHours = 0;
  int _durMinutes = 30;
  int _durSecs = 0;

  static const List<int> _distanceOptions = [
    25, 50, 75,
    100, 150, 200, 250, 300, 350, 400, 450, 500,
    550, 600, 650, 700, 750, 800, 850, 900, 950,
    1000, 1100, 1200, 1500, 2000, 2500, 3000,
  ];
  int _distance = 500; // 实际距离值（米），OCR 直接赋值时不吸附预设
  int get _closestDistanceIndex {
    int best = 0;
    int bestDiff = (_distanceOptions[0] - _distance).abs();
    for (int i = 1; i < _distanceOptions.length; i++) {
      final diff = (_distanceOptions[i] - _distance).abs();
      if (diff < bestDiff) { bestDiff = diff; best = i; }
    }
    return best;
  }

  // 心率：可选，null = 未填
  int? _avgHeartRate;
  int? _maxHeartRate;
  bool _heartRateEnabled = false;

  int? _calories;
  bool _caloriesEnabled = false;

  List<SwimSet> _swimSets = [];
  bool _swimSetsExpanded = false;

  int? _poolLengthMeters;
  int? _laps;
  String? _avgPace;
  int? _swolfAvg;
  int? _strokeCount;
  // 额外数据控制器（持久化，避免 build 中重建导致光标跳位）
  final TextEditingController _lapsCtrl        = TextEditingController();
  final TextEditingController _poolCtrl        = TextEditingController();
  final TextEditingController _paceCtrl        = TextEditingController();
  final TextEditingController _swolfCtrl       = TextEditingController();
  final TextEditingController _strokeCtrl      = TextEditingController();
  // 备注
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = widget.editSession;
    if (s != null) {
      _date = s.date;
      _distance = s.totalDistanceMeters ?? _distance;
      const maxPickerSec = 23 * 3600 + 59 * 60 + 59;
      final sec = s.durationSeconds > maxPickerSec ? maxPickerSec : s.durationSeconds;
      _durHours = sec ~/ 3600;
      final rem = sec % 3600;
      _durMinutes = rem ~/ 60;
      _durSecs = rem % 60;
      // 心率
      if (s.heartRateAvg != null || s.heartRateMax != null) {
        _heartRateEnabled = true;
        _avgHeartRate = s.heartRateAvg;
        _maxHeartRate = s.heartRateMax;
      }
      if (s.calories != null) {
        _caloriesEnabled = true;
        _calories = s.calories;
      }
      if (s.swimSets != null) _swimSets = List.of(s.swimSets!);
      // 高级指标
      _poolLengthMeters = s.poolLengthMeters;
      _laps        = s.laps;
      _avgPace     = s.avgPace;
      _swolfAvg    = s.swolfAvg;
      _strokeCount = s.strokeCount;
      _lapsCtrl.text   = s.laps?.toString() ?? '';
      _poolCtrl.text   = s.poolLengthMeters?.toString() ?? '';
      _paceCtrl.text   = s.avgPace ?? '';
      _swolfCtrl.text  = s.swolfAvg?.toString() ?? '';
      _strokeCtrl.text = s.strokeCount?.toString() ?? '';
      // 备注
      _notesController.text = s.notes ?? '';
    } else {
      _date = widget.initialDate ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _lapsCtrl.dispose();
    _poolCtrl.dispose();
    _paceCtrl.dispose();
    _swolfCtrl.dispose();
    _strokeCtrl.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _runOcrImport() async {
    setState(() => _ocrLoading = true);
    List<OcrPickResult> pickedList = [];
    try {
      pickedList = await _ocrService.pickAndParseImages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('识别失败：$e')));
      }
      if (mounted) setState(() => _ocrLoading = false);
      return;
    } finally {
      if (mounted) setState(() => _ocrLoading = false);
    }

    if (!mounted || pickedList.isEmpty) return;

    if (pickedList.length == 1) {
      final result = pickedList.first.swimResult;
      if (result.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未能识别到游泳数据，请重试或手动填写')),
        );
        return;
      }
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _OcrConfirmSheet(
          result: result,
          onConfirm: _applyOcrResult,
        ),
      );
      return;
    }

    int saved = 0;
    for (int i = 0; i < pickedList.length; i++) {
      if (!mounted) break;
      final picked = pickedList[i];
      if (picked.swimResult.isEmpty) continue;

      bool? confirmed;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _OcrConfirmSheet(
          result: picked.swimResult,
          imageCount: pickedList.length,
          currentIndex: i + 1,
          onConfirm: (result, accepted) async {
            confirmed = true;
            await _saveOcrAsSession(result, accepted);
          },
        ),
      );
      if (confirmed == true) saved++;
    }

    if (!mounted) return;
    if (saved > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已保存 $saved 条游泳记录')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _saveOcrAsSession(
      SwimOcrResult result, Set<String> accepted) async {
    int distanceM = 0;
    if (accepted.contains('distance') && result.distanceMeters != null) {
      distanceM = result.distanceMeters!;
    }

    int totalSeconds = 0;
    if (accepted.contains('duration')) {
      if (result.durationRaw != null) {
        final m =
            RegExp(r'(\d{1,2}):(\d{2}):(\d{2})').firstMatch(result.durationRaw!);
        if (m != null) {
          totalSeconds = int.parse(m.group(1)!) * 3600 +
              int.parse(m.group(2)!) * 60 +
              int.parse(m.group(3)!);
        }
      } else if (result.durationMinutes != null) {
        totalSeconds = result.durationMinutes! * 60;
      }
    }

    List<SwimSet>? swimSets;
    if (accepted.contains('swimStyle') && result.swimStyle != null) {
      final style = _styleFromString(result.swimStyle!);
      if (style != null) {
        swimSets = [SwimSet(style: style, distanceMeters: distanceM)];
      }
    }

    final session = WorkoutSession(
      id: context.read<WorkoutProvider>().generateId(),
      date: result.workoutDateTime ?? DateTime.now(),
      type: WorkoutType.swim,
      durationSeconds: totalSeconds,
      durationMinutes: totalSeconds ~/ 60,
      heartRateAvg: accepted.contains('avgHR') ? result.avgHeartRate : null,
      heartRateMax: accepted.contains('maxHR') ? result.maxHeartRate : null,
      calories: accepted.contains('calories') ? result.calories : null,
      swimSets: swimSets,
      totalDistanceMeters: distanceM > 0 ? distanceM : null,
      poolLengthMeters: accepted.contains('poolLength') ? result.poolLength : null,
      laps: accepted.contains('laps') ? result.laps : null,
      avgPace: accepted.contains('avgPace') ? result.avgPace : null,
      swolfAvg: accepted.contains('swolfAvg') ? result.swolfAvg : null,
      strokeCount: accepted.contains('strokeCount') ? result.strokeCount : null,
    );

    await context.read<WorkoutProvider>().addSession(session);
  }

  void _applyOcrResult(SwimOcrResult result, Set<String> accepted) {
    setState(() {
      _swimSets.clear();
      _swimSetsExpanded = false;
      _heartRateEnabled = false;
      _avgHeartRate = null;
      _maxHeartRate = null;
      _caloriesEnabled = false;
      _calories = null;
      _poolLengthMeters = null;
      _laps = null;
      _avgPace = null;
      _swolfAvg = null;
      _strokeCount = null;

      if (result.workoutDateTime != null) {
        _date = result.workoutDateTime!;
      }
      if (accepted.contains('distance') && result.distanceMeters != null) {
        _distance = result.distanceMeters!;
      }
      if (accepted.contains('duration') && result.durationRaw != null) {
        final reg = RegExp(r'(\d{1,2}):(\d{2}):(\d{2})');
        final m = reg.firstMatch(result.durationRaw!);
        if (m != null) {
          _durHours = int.parse(m.group(1)!);
          _durMinutes = int.parse(m.group(2)!);
          _durSecs = int.parse(m.group(3)!);
        }
      } else if (accepted.contains('duration') && result.durationMinutes != null) {
        _durHours = result.durationMinutes! ~/ 60;
        _durMinutes = result.durationMinutes! % 60;
        _durSecs = 0;
      }
      if (accepted.contains('calories') && result.calories != null) {
        _caloriesEnabled = true;
        _calories = result.calories!.clamp(100, 1500);
      }
      if (accepted.contains('avgHR') && result.avgHeartRate != null) {
        _heartRateEnabled = true;
        _avgHeartRate = result.avgHeartRate!.clamp(60, 200);
      }
      if (accepted.contains('maxHR') && result.maxHeartRate != null) {
        _heartRateEnabled = true;
        _maxHeartRate = result.maxHeartRate!.clamp(60, 220);
      }
      if (accepted.contains('swimStyle') && result.swimStyle != null) {
        final style = _styleFromString(result.swimStyle!);
        if (style != null) {
          final distM = result.distanceMeters ?? _distance;
          _swimSets
            ..clear()
            ..add(SwimSet(style: style, distanceMeters: distM));
          _swimSetsExpanded = true;
        }
      }
      if (accepted.contains('poolLength') && result.poolLength != null) {
        _poolLengthMeters = result.poolLength;
        _poolCtrl.text = _poolLengthMeters.toString();
      }
      if (accepted.contains('laps') && result.laps != null) {
        _laps = result.laps;
        _lapsCtrl.text = _laps.toString();
      }
      // 配速
      if (accepted.contains('avgPace') && result.avgPace != null) {
        _avgPace = result.avgPace;
        _paceCtrl.text = _avgPace!;
      }
      // SWOLF
      if (accepted.contains('swolfAvg') && result.swolfAvg != null) {
        _swolfAvg = result.swolfAvg;
        _swolfCtrl.text = _swolfAvg.toString();
      }
      if (accepted.contains('strokeCount') && result.strokeCount != null) {
        _strokeCount = result.strokeCount;
        _strokeCtrl.text = _strokeCount.toString();
      }
    });
  }

  SwimStyle? _styleFromString(String s) {
    switch (s) {
      case '蛙泳': return SwimStyle.breaststroke;
      case '自由泳': return SwimStyle.freestyle;
      case '仰泳': return SwimStyle.backstroke;
      case '蝶泳': return SwimStyle.butterfly;
      case '混合泳': return SwimStyle.medley;
      default: return null;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColors.swimAccent,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _date = DateTime(
        picked.year, picked.month, picked.day,
        _date.hour, _date.minute));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _date.hour, minute: _date.minute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColors.swimAccent,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _date = DateTime(
        _date.year, _date.month, _date.day,
        picked.hour, picked.minute));
  }

  Future<void> _save() async {
    final totalSeconds = _durHours * 3600 + _durMinutes * 60 + _durSecs;
    final durationMins = totalSeconds ~/ 60;
    final distanceM = _distance;

    final session = WorkoutSession(
      id: widget.editSession?.id ?? context.read<WorkoutProvider>().generateId(),
      date: _date,
      type: WorkoutType.swim,
      durationSeconds: totalSeconds,
      durationMinutes: durationMins,
      heartRateAvg: _heartRateEnabled ? _avgHeartRate : null,
      heartRateMax: _heartRateEnabled ? _maxHeartRate : null,
      calories: _caloriesEnabled ? _calories : null,
      swimSets: _swimSets.isNotEmpty ? List.of(_swimSets) : null,
      totalDistanceMeters: distanceM,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      poolLengthMeters: _poolLengthMeters,
      laps: _laps,
      avgPace: _avgPace,
      swolfAvg: _swolfAvg,
      strokeCount: _strokeCount,
    );

    await context.read<WorkoutProvider>().addSession(session);
    if (!mounted) return;

    if (widget.editSession != null) {
      Navigator.pop(context, true);
      return;
    }
    await _showSummary(session);
  }

  Future<void> _showSummary(WorkoutSession session) async {
    final durMins = session.durationInMinutes;
    final distDisplay = session.totalDistanceMeters != null
        ? ' · ${session.totalDistanceMeters} 米'
        : '';
    final setsDisplay = session.swimSets != null
        ? ' · ${session.swimSets!.length} 组'
        : '';
    await showSuccessDialog(
      context: context,
      typeKey: 'swim',
      typeEmoji: '🏊',
      typeLabel: '游泳',
      detailText: '$durMins 分钟$distDisplay$setsDisplay',
      isEdit: false,
    );
    if (!mounted) return;
    // 里程碑检查
    final streak = context.read<WorkoutProvider>().currentStreak;
    await checkAndShowMilestone(context, streak);
    if (!mounted) return;
    Navigator.pop(context); // screen
  }

  void _openAddSwimSetSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSwimSetSheet(
        onAdd: (set) => setState(() => _swimSets.add(set)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          _GradientHeader(
            onBack: () => Navigator.pop(context),
            title: widget.editSession != null ? '修改游泳记录 🏊' : '记录游泳 🏊',
            subtitle: widget.editSession != null ? '修改后点击保存' : '填写本次游泳数据',
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOcrImportCard(),
                  const SizedBox(height: 12),

                  _buildDateCard(),
                  const SizedBox(height: 12),

                  _buildDurationCard(),
                  const SizedBox(height: 12),

                  _buildDistanceCard(),
                  const SizedBox(height: 12),

                  _buildHeartRateCard(),
                  const SizedBox(height: 12),

                  _buildCaloriesCard(),
                  const SizedBox(height: 12),

                  _buildSwimSetsCard(),
                  const SizedBox(height: 12),

                  _buildExtraMetricsCard(),
                  const SizedBox(height: 12),

                  // 8. 备注
                  _buildNotesCard(),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: _SaveButton(onSave: _save),
    );
  }

  Widget _buildOcrImportCard() {
    return GestureDetector(
      onTap: _ocrLoading ? null : _runOcrImport,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: _ocrLoading
              ? const Color(0xFF1565C0).withValues(alpha:0.08)
              : const Color(0xFF1976D2).withValues(alpha:0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1976D2).withValues(alpha:0.55),
            width: 1.8,
          ),
        ),
        child: _ocrLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    '识别中... 📳',
                    style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xFF1976D2),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📱 从华为运动健康截图导入',
                          style: const TextStyle(
                            color: Color(0xFF1976D2),
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '自动识别运动数据，一键填入',
                          style: const TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF1976D2),
                    size: 14,
                  ),
                ],
              ),
        ),
    );
  }

  Widget _buildDateCard() {
    final theme = Theme.of(context);
    final months = ['', '1月', '2月', '3月', '4月', '5月', '6月',
        '7月', '8月', '9月', '10月', '11月', '12月'];
    final weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final isToday = _date.year == DateTime.now().year &&
        _date.month == DateTime.now().month &&
        _date.day == DateTime.now().day;
    final dateStr = isToday
        ? '今天'
        : '${months[_date.month]}${_date.day}日';
    final weekStr = isToday ? '' : '  ${weekdays[_date.weekday]}';
    final timeStr =
        '${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}';

    return _SectionCard(
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.swimAccent.withValues(alpha:0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.swimAccent.withValues(alpha:0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppColors.swimAccent, size: 13),
                      Text('日期',
                          style: TextStyle(
                              color: AppColors.swimAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      '$dateStr$weekStr',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.swimAccent.withValues(alpha:0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.swimAccent.withValues(alpha:0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.access_time_outlined,
                          color: AppColors.swimAccent, size: 13),
                      Text('时间',
                          style: TextStyle(
                              color: AppColors.swimAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      timeStr,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationCard() {
    final theme = Theme.of(context);

    String fmt(int h, int m, int s) {
      if (h > 0) {
        return '$h时${m.toString().padLeft(2, '0')}分${s.toString().padLeft(2, '0')}秒';
      }
      return '${m.toString().padLeft(2, '0')}分${s.toString().padLeft(2, '0')}秒';
    }

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.swimAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: AppColors.swimAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('时长', style: theme.textTheme.bodyMedium),
                  Text(
                    fmt(_durHours, _durMinutes, _durSecs),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.swimAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _durHours.clamp(0, 23),
                        ),
                        itemExtent: 38,
                        onSelectedItemChanged: (i) => setState(() => _durHours = i),
                        children: List.generate(
                          24,
                          (i) => Center(
                            child: Text(
                              '$i 时',
                              style: TextStyle(
                                color: theme.textTheme.bodyLarge?.color,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: _durMinutes,
                    ),
                    itemExtent: 38,
                    onSelectedItemChanged: (i) => setState(() => _durMinutes = i),
                    children: List.generate(
                      60,
                      (i) => Center(
                        child: Text(
                          '$i 分',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: _durSecs,
                    ),
                    itemExtent: 38,
                    onSelectedItemChanged: (i) => setState(() => _durSecs = i),
                    children: List.generate(
                      60,
                      (i) => Center(
                        child: Text(
                          '$i 秒',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 16,
                          ),
                        ),
                      ),
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

  Widget _buildDistanceCard() {
    final theme = Theme.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.swimAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pool_outlined,
                  color: AppColors.swimAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('距离', style: theme.textTheme.bodyMedium),
                  Text(
                    '$_distance 米',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.swimAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                initialItem: _closestDistanceIndex,
              ),
              itemExtent: 38,
              onSelectedItemChanged: (i) =>
                  setState(() => _distance = _distanceOptions[i]),
              children: _distanceOptions
                  .map(
                    (d) => Center(
                      child: Text(
                        '$d 米',
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateCard() {
    final theme = Theme.of(context);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite_outline,
                  color: Colors.pinkAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('平均心率', style: theme.textTheme.bodyMedium),
                    Text(
                      _heartRateEnabled ? '${_avgHeartRate ?? 120} bpm' : '未记录',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _heartRateEnabled
                            ? Colors.pinkAccent
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _heartRateEnabled,
                onChanged: (v) => setState(() {
                  _heartRateEnabled = v;
                  if (v && _avgHeartRate == null) _avgHeartRate = 120;
                }),
              ),
            ],
          ),
          if (_heartRateEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('60', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: (_avgHeartRate ?? 120).toDouble(),
                    min: 60,
                    max: 200,
                    divisions: 140,
                    activeColor: Colors.pinkAccent,
                    label: '$_avgHeartRate bpm',
                    onChanged: (v) =>
                        setState(() => _avgHeartRate = v.round()),
                  ),
                ),
                const Text('200', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCaloriesCard() {
    final theme = Theme.of(context);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.gymAccent.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_fire_department_outlined,
                    color: AppColors.gymAccent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('卡路里', style: theme.textTheme.bodyMedium),
                    Text(
                      _caloriesEnabled ? '$_calories kcal' : '未记录',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _caloriesEnabled
                            ? AppColors.gymAccent
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _caloriesEnabled,
                onChanged: (v) => setState(() {
                  _caloriesEnabled = v;
                  if (v && _calories == null) _calories = 400;
                }),
              ),
            ],
          ),
          if (_caloriesEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('100', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: (_calories ?? 400).toDouble(),
                    min: 100,
                    max: 1000,
                    divisions: 90,
                    activeColor: AppColors.gymAccent,
                    label: '$_calories kcal',
                    onChanged: (v) =>
                        setState(() => _calories = v.round()),
                  ),
                ),
                const Text('1000', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwimSetsCard() {
    final theme = Theme.of(context);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _swimSetsExpanded = !_swimSetsExpanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.swimAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.waves_outlined,
                    color: AppColors.swimAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('泳姿明细', style: theme.textTheme.bodyMedium),
                      Text(
                        _swimSets.isEmpty ? '可选，未添加' : '已添加 ${_swimSets.length} 组',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: _swimSets.isNotEmpty
                              ? AppColors.swimAccent
                              : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _swimSetsExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ],
            ),
          ),
          if (_swimSetsExpanded) ...[
            const SizedBox(height: 12),
            ..._swimSets.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SwimSetChip(
                      index: e.key,
                      set: e.value,
                      onDelete: () => setState(() => _swimSets.removeAt(e.key)),
                    ),
                  ),
                ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _openAddSwimSetSheet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.swimAccent.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.swimAccent.withValues(alpha: 0.06),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add, color: AppColors.swimAccent, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '+ 添加一组',
                      style: TextStyle(
                        color: AppColors.swimAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtraMetricsCard() {
    final theme = Theme.of(context);

    Widget metricTile({
      required String label,
      required TextEditingController controller,
      required String hint,
      required TextInputType keyboardType,
      required ValueChanged<String> onChanged,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(label, style: theme.textTheme.bodyMedium),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  hintText: hint,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      );
    }

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.swimAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart_outlined,
                  color: AppColors.swimAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text('额外数据', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          metricTile(
            label: '趟数',
            controller: _lapsCtrl,
            hint: '如 36',
            keyboardType: TextInputType.number,
            onChanged: (v) => _laps = int.tryParse(v),
          ),
          metricTile(
            label: '泳池长度',
            controller: _poolCtrl,
            hint: '25 / 50',
            keyboardType: TextInputType.number,
            onChanged: (v) => _poolLengthMeters = int.tryParse(v),
          ),
          metricTile(
            label: '平均配速',
            controller: _paceCtrl,
            hint: "如 6'43\"",
            keyboardType: TextInputType.text,
            onChanged: (v) => _avgPace = v.isEmpty ? null : v,
          ),
          metricTile(
            label: 'SWOLF',
            controller: _swolfCtrl,
            hint: '如 102',
            keyboardType: TextInputType.number,
            onChanged: (v) => _swolfAvg = int.tryParse(v),
          ),
          metricTile(
            label: '划水次数',
            controller: _strokeCtrl,
            hint: '如 427',
            keyboardType: TextInputType.number,
            onChanged: (v) => _strokeCount = int.tryParse(v),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    final theme = Theme.of(context);

    return _SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.swimAccent.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_note_outlined,
                color: AppColors.swimAccent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _notesController,
              maxLines: 1,
              maxLength: 80,
              decoration: InputDecoration(
                hintText: '备注（可选）',
                border: InputBorder.none,
                counterText: '',
                filled: false,
                hintStyle: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 15,
                ),
              ),
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientHeader extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  final String subtitle;

  const _GradientHeader({
    required this.onBack,
    this.title = '记录游泳 🏊',
    this.subtitle = '填写本次游泳数据',
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, statusBarHeight + 12, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF003A5C),
            Color(0xFF005C8A),
            Color(0xFF007BB5),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: child,
    );
  }
}

class _SwimSetChip extends StatelessWidget {
  final int index;
  final SwimSet set;
  final VoidCallback onDelete;

  const _SwimSetChip({
    required this.index,
    required this.set,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.swimAccent.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.swimAccent.withValues(alpha:0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.swimAccent.withValues(alpha:0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: AppColors.swimAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${_styleEmoji(set.style)} ${_styleLabel(set.style)}',
            style: theme.textTheme.bodyLarge,
          ),
          const Spacer(),
          Text(
            '${set.distanceMeters}m',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.swimAccent, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onSave;

  const _SaveButton({required this.onSave});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.swimAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save_outlined, size: 20),
              SizedBox(width: 8),
              Text(
                '保存记录',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSwimSetSheet extends StatefulWidget {
  final ValueChanged<SwimSet> onAdd;

  const _AddSwimSetSheet({required this.onAdd});

  @override
  State<_AddSwimSetSheet> createState() => _AddSwimSetSheetState();
}
class _AddSwimSetSheetState extends State<_AddSwimSetSheet> {
  SwimStyle _style = SwimStyle.freestyle;
  int _customDist = 200;
  final TextEditingController _distController = TextEditingController(text: "200");
  static const List<int> _quickOptions = [25, 50, 100, 200, 400, 500, 800, 1000];

  @override
  void dispose() {
    _distController.dispose();
    super.dispose();
  }

  void _setDist(int v) {
    setState(() {
      _customDist = v;
      _distController.text = '$v';
      _distController.selection = TextSelection.fromPosition(
        TextPosition(offset: _distController.text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖动条
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
          Text('添加泳姿明细', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 20),
          Text('泳姿', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SwimStyle.values.map((s) => _StyleChip(
              label: '${_styleEmoji(s)} ${_styleLabel(s)}',
              selected: _style == s,
              onTap: () => setState(() => _style = s),
            )).toList(),
          ),

          const SizedBox(height: 20),
          Text('距离', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          // 快捷选择（Wrap 自动换行）
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickOptions.map((d) => _StyleChip(
              label: '${d}m',
              selected: _customDist == d,
              onTap: () => _setDist(d),
            )).toList(),
          ),
          const SizedBox(height: 14),
          // 自定义输入
          Row(
            children: [
              const Text('自定义：', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                height: 42,
                child: TextField(
                  controller: _distController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffixText: 'm',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.swimAccent.withValues(alpha:0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.swimAccent, width: 2),
                    ),
                  ),
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null && n > 0) setState(() => _customDist = n);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onAdd(SwimSet(
                  style: _style,
                  distanceMeters: _customDist,
                ));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.swimAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '添加',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StyleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.swimAccent.withValues(alpha:0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.swimAccent
                : Colors.grey.withValues(alpha:0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.swimAccent
                : theme.textTheme.bodyMedium?.color,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
//  完成确认
// OCR result confirmation
class _OcrConfirmSheet extends StatefulWidget {
  final SwimOcrResult result;
  final void Function(SwimOcrResult result, Set<String> accepted) onConfirm;
  final int imageCount;
  final int currentIndex;

  const _OcrConfirmSheet({
    required this.result,
    required this.onConfirm,
    this.imageCount = 1,
    this.currentIndex = 1,
  });

  @override
  State<_OcrConfirmSheet> createState() => _OcrConfirmSheetState();
}

class _OcrConfirmSheetState extends State<_OcrConfirmSheet> {
  late final Set<String> _accepted;

  @override
  void initState() {
    super.initState();
    _accepted = {};
    final r = widget.result;
    if (r.distanceMeters != null) _accepted.add('distance');
    if (r.durationMinutes != null) _accepted.add('duration');
    if (r.calories != null) _accepted.add('calories');
    if (r.avgHeartRate != null) _accepted.add('avgHR');
    if (r.maxHeartRate != null) _accepted.add('maxHR');
    if (r.swimStyle != null) _accepted.add('swimStyle');
    if (r.laps != null) _accepted.add('laps');
    if (r.poolLength != null) _accepted.add('poolLength');
    if (r.avgPace != null) _accepted.add('avgPace');
    if (r.swolfAvg != null) _accepted.add('swolfAvg');
    if (r.strokeCount != null) _accepted.add('strokeCount');
    if (r.bestPace != null) _accepted.add('bestPace');
    if (r.strokeRate != null) _accepted.add('strokeRate');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final r = widget.result;

    final coreItems = <_OcrItem>[
      _OcrItem(
        key: 'distance',
        label: '总距离',
        value: r.distanceMeters != null ? '${r.distanceMeters} 米' : null,
        icon: Icons.pool_outlined,
        fillable: true,
      ),
      _OcrItem(
        key: 'duration',
        label: '运动时长',
        value: r.durationRaw ??
            (r.durationMinutes != null ? '${r.durationMinutes} 分钟' : null),
        icon: Icons.timer_outlined,
        fillable: true,
      ),
      _OcrItem(
        key: 'calories',
        label: '卡路里',
        value: r.calories != null ? '${r.calories} 千卡' : null,
        icon: Icons.local_fire_department_outlined,
        fillable: true,
      ),
      _OcrItem(
        key: 'avgHR',
        label: '平均心率',
        value: r.avgHeartRate != null ? '${r.avgHeartRate} bpm' : null,
        icon: Icons.favorite_outline,
        fillable: true,
      ),
      _OcrItem(
        key: 'maxHR',
        label: '最大心率',
        value: r.maxHeartRate != null ? '${r.maxHeartRate} bpm' : null,
        icon: Icons.monitor_heart_outlined,
        fillable: true,
      ),
      _OcrItem(
        key: 'swimStyle',
        label: '主泳姿',
        value: r.swimStyle,
        icon: Icons.waves_outlined,
        fillable: true,
      ),
      _OcrItem(
        key: 'laps',
        label: '趟数',
        value: r.laps != null ? '${r.laps} 趟' : null,
        icon: Icons.repeat_outlined,
        fillable: true,
      ),
      _OcrItem(
        key: 'poolLength',
        label: '泳池长度',
        value: r.poolLength != null ? '${r.poolLength} 米' : null,
        icon: Icons.straighten_outlined,
        fillable: true,
      ),
      _OcrItem(
        key: 'avgPace',
        label: '平均配速',
        value: r.avgPace != null ? '${r.avgPace} /100米' : null,
        icon: Icons.speed_outlined,
        fillable: true,
      ),
      _OcrItem(
        key: 'strokeCount',
        label: '划水次数',
        value: r.strokeCount != null ? '${r.strokeCount} 次' : null,
        icon: Icons.water_drop_outlined,
        fillable: true,
      ),
    ];

    final xiaomiItems = <_OcrItem>[
      _OcrItem(
        key: 'bestPace',
        label: '最佳配速',
        value: r.bestPace != null ? '${r.bestPace} /100米' : null,
        icon: Icons.rocket_launch_outlined,
        fillable: true,
      ),
      _OcrItem(
        key: 'swolfAvg',
        label: '平均 SWOLF',
        value: r.swolfAvg != null ? '${r.swolfAvg}' : null,
        icon: Icons.water_outlined,
        fillable: true,
      ),
      _OcrItem(
        key: 'swolfBest',
        label: '最佳 SWOLF',
        value: r.swolfBest != null ? '${r.swolfBest}' : null,
        icon: Icons.star_outline,
        fillable: true,
      ),
      _OcrItem(
        key: 'strokeRate',
        label: '平均划频',
        value: r.strokeRate != null ? '${r.strokeRate} 次/趟' : null,
        icon: Icons.rowing_outlined,
        fillable: true,
      ),
    ];

    final hasExtendedData = r.bestPace != null ||
        r.swolfAvg != null ||
        r.swolfBest != null ||
        r.strokeRate != null;

    Color brandColor;
    String brandEmoji;
    switch (r.sourceBrand) {
      case OcrSourceBrand.huawei:
        brandColor = const Color(0xFFCF0A2C); // 华为红
        brandEmoji = '🔴';
      case OcrSourceBrand.xiaomi:
        brandColor = const Color(0xFFFF6900); // 小米橙
        brandEmoji = '🟠';
      case OcrSourceBrand.unknown:
        brandColor = Colors.grey;
        brandEmoji = '⚪';
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖动条
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

          // 标题行
          Row(
            children: [
              const Text('📳', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('识别结果确认',
                    style: theme.textTheme.headlineMedium),
              ),
              if (widget.imageCount > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.currentIndex} / ${widget.imageCount}',
                    style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: brandColor.withValues(alpha:0.4), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(brandEmoji,
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text(
                      '识别来源：${r.sourceBrand.displayName}',
                      style: TextStyle(
                        color: brandColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Text(
            '勾选的字段将填入表单，也可以取消勾选。',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 14),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...coreItems.map((item) => _buildOcrRow(item, theme)),

                  if (hasExtendedData) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(
                          width: 30,
                          child: Divider(thickness: 1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '扩展识别数据',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: Divider(thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...xiaomiItems.map((item) => _buildOcrRow(item, theme)),
                  ],

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 底部按钮
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onConfirm(widget.result, Set.of(_accepted));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '填入表单',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrRow(_OcrItem item, ThemeData theme) {
    final recognized = item.value != null;
    final canToggle = recognized && item.fillable;
    final checked = item.fillable && _accepted.contains(item.key);

    // Row visual style states
    late Color borderColor;
    late Color bgColor;
    Color valueColor;
    FontWeight valueFW;

    if (!recognized) {
      borderColor = Colors.grey.withValues(alpha:0.2);
      bgColor = Colors.transparent;
      valueColor = Colors.grey.shade400;
      valueFW = FontWeight.normal;
    } else if (!item.fillable) {
      // 娴犲懎鐫嶇粈鐚寸窗閽冩繄浼嗛懝鑼剁殶
      borderColor = Colors.blueGrey.withValues(alpha:0.25);
      bgColor = Colors.blueGrey.withValues(alpha:0.05);
      valueColor = Colors.blueGrey.shade600;
      valueFW = FontWeight.w500;
    } else if (checked) {
      borderColor = Colors.green.withValues(alpha:0.45);
      bgColor = Colors.green.withValues(alpha:0.08);
      valueColor = Colors.green.shade700;
      valueFW = FontWeight.w600;
    } else {
      borderColor = Colors.grey.withValues(alpha:0.25);
      bgColor = Colors.transparent;
      valueColor = Colors.grey.shade600;
      valueFW = FontWeight.normal;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GestureDetector(
        onTap: canToggle
            ? () => setState(() {
                  if (checked) {
                    _accepted.remove(item.key);
                  } else {
                    _accepted.add(item.key);
                  }
                })
            : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.3),
          ),
          child: Row(
            children: [
              // 图标
              Icon(
                item.icon,
                size: 20,
                color: recognized
                    ? (checked ? Colors.green : Colors.blueGrey)
                    : Colors.grey.shade400,
              ),
              const SizedBox(width: 12),

              // 标签
              SizedBox(
                child: Text(
                  item.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: recognized ? null : Colors.grey.shade400,
                    fontSize: 13.5,
                  ),
                ),
              ),

              // 值
              Expanded(
                child: Text(
                  recognized ? item.value! : '未识别到',
                  style: TextStyle(
                    color: valueColor,
                    fontWeight: valueFW,
                    fontSize: 13.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 状态图标
              if (!item.fillable && recognized)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '参考',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500),
                  ),
                )
              else if (item.fillable && recognized)
                Icon(
                  checked
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: checked ? Colors.green : Colors.grey.shade400,
                  size: 20,
                )
              else
                const Icon(Icons.cancel_outlined,
                    color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _OcrItem {
  final String key;
  final String label;
  final String? value;
  final IconData icon;

  final bool fillable;

  const _OcrItem({
    required this.key,
    required this.label,
    required this.value,
    required this.icon,
    this.fillable = true,
  });
}
