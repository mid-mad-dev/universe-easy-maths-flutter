import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../core/app_colors.dart';
import '../models/lesson.dart';
import '../services/progress_service.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final List<Lesson> lessons;
  const LessonScreen({super.key, required this.lesson, required this.lessons});
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final progress = ProgressService();
  VideoPlayerController? controller;
  bool initializing = true;
  bool complete = false;
  String? error;
  bool _disposed = false;
  int _loadGeneration = 0;
  double _lastSavedPercent = -10;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    _disposed = true;
    _disposeController();
    super.dispose();
  }

  Future<void> _disposeController() async {
    final c = controller;
    controller = null;
    if (c != null) {
      c.removeListener(_watchProgress);
      try {
        await c.dispose();
      } catch (_) {
        // Controller may already have failed to initialize.
      }
    }
  }

  Future<void> load() async {
    final generation = ++_loadGeneration;
    await _disposeController();
    if (_disposed || generation != _loadGeneration) return;

    setState(() {
      initializing = true;
      error = null;
    });

    try {
      final saved = await progress.getLessonProgress(widget.lesson.id);
      final videoUrl = widget.lesson.videoUrl?.trim() ?? '';
      if (_disposed || generation != _loadGeneration) return;

      final wasSeen = saved?['seen'] == true;

      if (videoUrl.isEmpty) {
        setState(() {
          initializing = false;
          complete = wasSeen;
        });
        return;
      }

      // Fetching the signed URL and initializing playback can hang on a bad
      // network, so time both out instead of spinning forever.
      final playable = await _fetchPlayableUrl(
        widget.lesson.id,
        videoUrl,
      ).timeout(const Duration(seconds: 25));
      if (_disposed || generation != _loadGeneration) return;
      if (playable == null || playable.isEmpty) {
        throw Exception('Could not build a playable URL for this video.');
      }

      final player = VideoPlayerController.networkUrl(Uri.parse(playable));
      controller = player;
      await player.initialize().timeout(const Duration(seconds: 40));
      if (_disposed || generation != _loadGeneration || controller != player) {
        try {
          await player.dispose();
        } catch (_) {}
        return;
      }

      player.addListener(_watchProgress);
      setState(() {
        initializing = false;
        complete = wasSeen;
      });
      try {
        await player.play();
      } catch (_) {
        // Playback starts lazily; tapping the screen retries.
      }
    } catch (e) {
      if (_disposed || generation != _loadGeneration) return;
      final friendly = e is TimeoutException
          ? 'The video took too long to load. '
                'Check your internet connection and tap Retry.'
          : e.toString().replaceFirst('Exception: ', '');
      setState(() {
        initializing = false;
        error = friendly;
      });
    }
  }

  Future<String?> _fetchPlayableUrl(String lessonId, String stored) async {
    if (stored.startsWith('http://') || stored.startsWith('https://')) {
      return stored;
    }
    Object? primaryError;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'get-lesson-url',
        body: {'lesson_id': lessonId},
      );
      if (response.status < 400) {
        final data = response.data;
        if (data is Map && data['url'] != null) {
          return data['url'].toString();
        }
        primaryError = Exception('The server did not return a video URL.');
      } else {
        final data = response.data;
        final message = data is Map ? (data['error'] ?? data['message']) : data;
        primaryError = Exception(message?.toString() ?? 'Video access denied.');
      }
    } catch (e) {
      primaryError = e;
    }

    throw Exception('Could not load the video: $primaryError');
  }

  Future<void> _watchProgress() async {
    final c = controller;
    if (_disposed || c == null || !c.value.isInitialized) return;
    final duration = c.value.duration.inMilliseconds;
    if (duration <= 0) return;
    final position = c.value.position.inMilliseconds;
    final pct = position / duration * 100;
    if (!complete && pct >= 90) {
      complete = true;
      await progress.saveProgress(
        lessonId: widget.lesson.id,
        chapterId: widget.lesson.chapterId,
        watchedPercentage: 100,
      );
      if (mounted && !_disposed) setState(() {});
    } else if (!complete && pct > 0 && (pct - _lastSavedPercent).abs() >= 5) {
      _lastSavedPercent = pct;
      await progress.saveProgress(
        lessonId: widget.lesson.id,
        chapterId: widget.lesson.chapterId,
        watchedPercentage: pct,
      );
    }
  }

  Future<void> markComplete() async {
    await progress.saveProgress(
      lessonId: widget.lesson.id,
      chapterId: widget.lesson.chapterId,
      watchedPercentage: 100,
    );
    if (mounted && !_disposed) setState(() => complete = true);
  }

  void togglePlay() {
    final c = controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    if (mounted) setState(() {});
  }

  void next() {
    final i = widget.lessons.indexWhere((x) => x.id == widget.lesson.id);
    if (i < 0 || i + 1 >= widget.lessons.length) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chapter completed!')));
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          lesson: widget.lessons[i + 1],
          lessons: widget.lessons,
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    if (initializing) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.purple),
      );
    }
    final c = controller;
    if (c != null && c.value.isInitialized) {
      return GestureDetector(
        onTap: togglePlay,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: c.value.aspectRatio,
                child: VideoPlayer(c),
              ),
            ),
            if (!c.value.isPlaying)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 46,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      );
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                size: 40,
                color: AppColors.mutedText,
              ),
              const SizedBox(height: 14),
              Text(
                'Video error: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 18),
              ElevatedButton(onPressed: load, child: const Text('RETRY')),
            ],
          ),
        ),
      );
    }
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Video not uploaded yet.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final showProgress = c != null && c.value.isInitialized;
    return Scaffold(
      backgroundColor: AppColors.videoBackground,
      appBar: AppBar(
        title: Text('LESSON ${widget.lesson.number}'),
        backgroundColor: AppColors.videoBackground,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: AppColors.videoBackground,
              child: _buildVideoArea(),
            ),
          ),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              // Cap the info panel so it can never overflow the Column below
              // the video (unbounded main axis for non-flex children).
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.gradientTeal,
                  AppColors.gradientNavy,
                  AppColors.gradientPurple,
                ],
                stops: [0, 0.58, 1],
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.lesson.title,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (complete)
                          const Icon(Icons.check_circle, color: AppColors.teal),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.lesson.description,
                      style: const TextStyle(color: AppColors.secondaryText),
                    ),
                    if (showProgress) ...[
                      const SizedBox(height: 10),
                      VideoProgressIndicator(
                        c,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        colors: const VideoProgressColors(
                          playedColor: AppColors.purple,
                          bufferedColor: AppColors.border,
                          backgroundColor: AppColors.lightPurple,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: complete ? null : markComplete,
                            child: Text(
                              complete ? 'SEEN ✓' : 'MARK AS COMPLETE',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: next,
                            child: const Text('NEXT LESSON →'),
                          ),
                        ),
                      ],
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
}
