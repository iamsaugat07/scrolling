// ================= widgets/video_post.dart =================
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoPost extends StatefulWidget {
  final String videoUrl;
  final bool isMuted;
  final Function(bool) onMuteChanged;

  const VideoPost({
    super.key,
    required this.videoUrl,
    required this.isMuted,
    required this.onMuteChanged,
  });

  @override
  State<VideoPost> createState() => _VideoPostState();
}

class _VideoPostState extends State<VideoPost> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isVisible = false;
  bool _isMuted = true;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.isMuted;
    _initializeController();
  }

  @override
  void didUpdateWidget(VideoPost oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update mute state if global mute changes
    if (oldWidget.isMuted != widget.isMuted) {
      setState(() {
        _isMuted = widget.isMuted;
        _controller.setVolume(_isMuted ? 0.0 : 1.0);
      });
    }
  }

  Future<void> _initializeController() async {
    // For HLS streams
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    _controller.addListener(_videoListener);

    try {
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.setVolume(_isMuted ? 0.0 : 1.0);

      if (mounted) {
        setState(() {
          _isInitialized = true;

          // Start playing if the video is visible
          if (_isVisible) {
            _controller.play();
            _isPlaying = true;
          }
        });
      }
    } catch (e) {
      print("Error initializing video: $e");
    }
  }

  void _videoListener() {
    // Update loading progress
    final Duration? position = _controller.value.position;
    final Duration? duration = _controller.value.duration;

    if (position != null && duration != null && duration.inMilliseconds > 0) {
      setState(() {
        _loadingProgress = position.inMilliseconds / duration.inMilliseconds;
      });
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
      widget.onMuteChanged(_isMuted);
    });
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    final isVisible = info.visibleFraction > 0.5;

    if (_isVisible != isVisible) {
      setState(() {
        _isVisible = isVisible;
      });

      // Only autoplay if already initialized
      if (_isInitialized) {
        if (_isVisible) {
          _controller.play();
          _isPlaying = true;
        } else {
          _controller.pause();
          _isPlaying = false;
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: _handleVisibilityChanged,
      child: AspectRatio(
        aspectRatio: _isInitialized ? _controller.value.aspectRatio : 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player
            GestureDetector(
              onTap: _togglePlayPause,
              child: _isInitialized
                  ? VideoPlayer(_controller)
                  : Container(color: Colors.black),
            ),

            // Loading indicator
            if (!_isInitialized) const CircularProgressIndicator(),

            // Buffer progress indicator
            if (_isInitialized && _loadingProgress < 1.0 && !_isPlaying)
              CircularProgressIndicator(
                value: _loadingProgress,
                strokeWidth: 2,
              ),

            // Play/pause button
            if (_isInitialized)
              AnimatedOpacity(
                opacity: _isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),

            // Mute button (bottom right)
            if (_isInitialized)
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 16,
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
