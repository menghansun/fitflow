import 'package:flutter/material.dart';
import '../../models/workout_session.dart';
import '../../services/exercise_library.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';


class ExerciseGalleryScreen extends StatefulWidget {
  const ExerciseGalleryScreen({super.key});

  @override
  State<ExerciseGalleryScreen> createState() => _ExerciseGalleryScreenState();
}

class _ExerciseGalleryScreenState extends State<ExerciseGalleryScreen> {
  MuscleGroup _selected = MuscleGroup.chest;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _query.isEmpty
        ? ExerciseLibrary.getMetasForGroup(_selected)
        : ExerciseLibrary.search(_query);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2450C7),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('选择练习'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF2450C7),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: '搜索练习',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
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
          ),
          if (_query.isEmpty)
            SizedBox(
              height: 56,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                scrollDirection: Axis.horizontal,
                itemCount: MuscleGroup.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final group = MuscleGroup.values[index];
                  final selected = group == _selected;
                  return InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => setState(() => _selected = group),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFE9F0FF) : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected ? const Color(0xFF2450C7) : const Color(0xFFD7DDE8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(group.emoji),
                          const SizedBox(width: 6),
                          Text(
                            group.displayName,
                            style: TextStyle(
                              color: selected ? const Color(0xFF2450C7) : const Color(0xFF596579),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) => _ExercisePreviewCard(meta: items[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercisePreviewCard extends StatelessWidget {
  final ExerciseMeta meta;
  const _ExercisePreviewCard({required this.meta});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _ExerciseDetailScreen(meta: meta)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x110F172A),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meta.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 112,
                  height: 92,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE4E7EC)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: meta.imageAsset.isNotEmpty
                      ? Image.asset(meta.imageAsset, fit: BoxFit.cover)
                      : const Icon(Icons.image_outlined, color: Color(0xFF98A2B3)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TagChip(label: meta.difficulty, bg: const Color(0xFF3D7BF6), fg: Colors.white),
                      _TagChip(label: meta.equipment, bg: const Color(0xFFF3F4F6), fg: const Color(0xFF475467)),
                      _TagChip(label: meta.category, bg: const Color(0xFFEAFBF0), fg: const Color(0xFF1E9D57)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _MusclePlaceholder(group: meta.group),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseDetailScreen extends StatelessWidget {
  final ExerciseMeta meta;
  const _ExerciseDetailScreen({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(meta.name),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x110F172A), blurRadius: 16, offset: Offset(0, 6))],
            ),
            clipBehavior: Clip.antiAlias,
            child: meta.videoUrl != null && meta.videoUrl!.isNotEmpty
                ? _VideoPlayerWidget(videoUrl: meta.videoUrl!)
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_outline, size: 54, color: Color(0xFF2450C7)),
                        SizedBox(height: 12),
                        Text('示范视频占位', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        SizedBox(height: 6),
                        Text('素材后续补', style: TextStyle(color: Color(0xFF667085))),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(label: meta.difficulty, bg: const Color(0xFF3D7BF6), fg: Colors.white),
              _TagChip(label: meta.equipment, bg: const Color(0xFFF3F4F6), fg: const Color(0xFF475467)),
              _TagChip(label: meta.category, bg: const Color(0xFFEAFBF0), fg: const Color(0xFF1E9D57)),
            ],
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: '目标肌群',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MuscleBoard(group: meta.group, muscleAsset: meta.muscleAsset),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: meta.targetMuscles
                      .map((e) => _TagChip(label: e, bg: const Color(0xFFFFF1F1), fg: const Color(0xFFD92D20)))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: '动作要领',
            child: Column(
              children: [
                for (int i = 0; i < meta.cues.length; i++)
                  _BulletRow(index: i + 1, text: meta.cues[i]),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: '注意事项',
            child: Column(
              children: meta.tips.map((e) => _BulletTip(text: e)).toList(),
            ),
          ),
        ],
      ),
    );
  }
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


class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _DetailSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x110F172A), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  final int index;
  final String text;
  const _BulletRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFEAF0FF), shape: BoxShape.circle),
            child: Text('$index', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2450C7))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.5, color: Color(0xFF344054)))),
        ],
      ),
    );
  }
}

class _BulletTip extends StatelessWidget {
  final String text;
  const _BulletTip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 7, color: Color(0xFF98A2B3)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.5, color: Color(0xFF344054)))),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _TagChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _MusclePlaceholder extends StatelessWidget {
  final MuscleGroup group;
  const _MusclePlaceholder({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(group.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          const Icon(Icons.accessibility_new, color: Color(0xFFEF4444), size: 26),
          const SizedBox(height: 4),
          Text(group.displayName, style: const TextStyle(fontSize: 11, color: Color(0xFF667085))),
        ],
      ),
    );
  }
}

class _MuscleBoard extends StatelessWidget {
  final MuscleGroup group;
  final String? muscleAsset;
  const _MuscleBoard({required this.group, this.muscleAsset});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 有图时显示图片，没有时显示占位
    if (muscleAsset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          muscleAsset!,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _placeholder(isDark),
        ),
      );
    }
    return _placeholder(isDark);
  }

  Widget _placeholder(bool isDark) => Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2035) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.accessibility_new,
                size: 52, color: Color(0xFFEF4444)),
            const SizedBox(height: 8),
            Text(
              '${group.emoji} ${group.displayName}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
            ),
            const SizedBox(height: 4),
            const Text('肌肉示意图即将上线',
                style: TextStyle(fontSize: 11, color: Color(0xFF98A2B3))),
          ],
        ),
      );
}
