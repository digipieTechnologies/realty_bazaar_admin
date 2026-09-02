// File: lib/widgets/media/full_screen_media_viewer.dart
// Purpose: Reusable full-screen media viewer for images (with zoom/keyboard shortcuts) and videos (with playback controls) in admin panel.

import 'dart:io' as io;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../app/app_colors.dart';
import '../../models/media_model.dart';
import '../common/cached_image.dart';

class FullScreenMediaViewer extends StatefulWidget {
  final List<MediaModel> medias;
  final int initialIndex;

  const FullScreenMediaViewer({super.key, required this.medias, this.initialIndex = 0});

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _nextPage() {
    if (_currentIndex < widget.medias.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _previousPage();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _nextPage();
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Media PageView
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.medias.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final media = widget.medias[index];
                  if (media.type == 'video') {
                    return _VideoPageItem(media: media);
                  } else {
                    return _ImagePageItem(media: media);
                  }
                },
              ),
            ),

            // Top Overlay Bar: Close Button, Counter
            Positioned(
              top: MediaQuery.of(context).padding.top + 16.0,
              left: 24.0,
              right: 24.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28.0),
                    tooltip: 'common.close'.tr(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'media_counter'.tr(args: ['${_currentIndex + 1}', '${widget.medias.length}']),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 48.0), // Spacer balancing close button
                ],
              ),
            ),

            // Left Navigation Arrow Overlay
            if (widget.medias.length > 1 && _currentIndex > 0)
              Positioned(
                left: 24.0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.black.withOpacity(0.5),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 32.0),
                      onPressed: _previousPage,
                    ),
                  ),
                ),
              ),

            // Right Navigation Arrow Overlay
            if (widget.medias.length > 1 && _currentIndex < widget.medias.length - 1)
              Positioned(
                right: 24.0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.black.withOpacity(0.5),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 32.0),
                      onPressed: _nextPage,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ImagePageItem extends StatelessWidget {
  final MediaModel media;

  const _ImagePageItem({required this.media});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        minScale: 1.0,
        maxScale: 4.0,
        child: CachedImage(
          imageUrl: media.url,
          imageBytes: media.bytes,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          ignoring: true,
          errorWidget: (context) => const _ErrorStateWidget(),
        ),
      ),
    );
  }
}

class _VideoPageItem extends StatefulWidget {
  final MediaModel media;

  const _VideoPageItem({required this.media});

  @override
  State<_VideoPageItem> createState() => _VideoPageItemState();
}

class _VideoPageItemState extends State<_VideoPageItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final url = widget.media.url;
    if (url == null || url.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    try {
      final isNetwork = url.startsWith('http') || url.startsWith('https') || kIsWeb;
      if (isNetwork) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        _controller = VideoPlayerController.file(io.File(url));
      }

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller!.play();
        _controller!.setLooping(true);
      }
    } catch (e) {
      debugPrint('[VideoPageItem] Init error: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _ErrorStateWidget(message: 'failed_to_play_video'.tr());
    }

    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(_controller!),

            // Video Controls Overlay
            _VideoControlsOverlay(controller: _controller!),
          ],
        ),
      ),
    );
  }
}

class _VideoControlsOverlay extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoControlsOverlay({required this.controller});

  @override
  State<_VideoControlsOverlay> createState() => _VideoControlsOverlayState();
}

class _VideoControlsOverlayState extends State<_VideoControlsOverlay> {
  bool _isMuted = false;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.controller.value.volume == 0.0;
    widget.controller.addListener(_videoListener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_videoListener);
    super.dispose();
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  void _togglePlay() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        widget.controller.pause();
      } else {
        widget.controller.play();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      widget.controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final position = value.position;
    final duration = value.duration;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isVisible = !_isVisible;
        });
      },
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Center Play/Pause button overlay
            if (_isVisible)
              Center(
                child: AnimatedOpacity(
                  opacity: _isVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    iconSize: 64.0,
                    icon: Icon(
                      value.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                      color: Colors.white.withOpacity(0.85),
                    ),
                    onPressed: _togglePlay,
                  ),
                ),
              ),

            // Bottom controls bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                opacity: _isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Video Seek Progress Bar
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.0,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: Colors.white.withOpacity(0.3),
                          thumbColor: AppColors.primary,
                        ),
                        child: Slider(
                          value: position.inMilliseconds.toDouble(),
                          min: 0.0,
                          max: duration.inMilliseconds.toDouble() > 0.0
                              ? duration.inMilliseconds.toDouble()
                              : 1.0,
                          onChanged: (val) {
                            widget.controller.seekTo(Duration(milliseconds: val.toInt()));
                          },
                        ),
                      ),

                      // Control items
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: _togglePlay,
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),

                          IconButton(
                            icon: Icon(
                              _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                              color: Colors.white,
                            ),
                            onPressed: _toggleMute,
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
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _ErrorStateWidget extends StatelessWidget {
  final String? message;

  const _ErrorStateWidget({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white38, size: 48.0),
          const SizedBox(height: 12.0),
          Text(
            message ?? 'failed_to_load_media'.tr(),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
