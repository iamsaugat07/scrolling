import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reelscroll/provider/audio_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Provider to manage active video controllers
final activeVideoControllersProvider =
    StateProvider<Map<String, VideoPlayerController>>((ref) {
  return {};
});

// This provider tracks which video is currently visible and playing
final currentPlayingVideoProvider = StateProvider<String?>((ref) {
  return null;
});

// Provider to manage video player state for a specific video
class VideoControllerNotifier extends StateNotifier<VideoPlayerController?> {
  final String videoUrl;
  final String videoId;
  final int maxActiveControllers = 2;

  VideoControllerNotifier(this.videoUrl, this.videoId) : super(null) {
    _initializeController();
  }

  Future<void> _initializeController() async {
    // Check if this is an HLS stream by looking for m3u8 extension
    final isHlsStream = videoUrl.toLowerCase().endsWith('.m3u8');

    // Create the controller with appropriate options for HLS streams
    final controller = VideoPlayerController.network(
      videoUrl,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        // For HLS streams, consider setting these additional options:
        // - Buffering configuration
        // - HTTP headers if needed for authorization
      ),
      formatHint: isHlsStream
          ? VideoFormat.hls
          : null, // Explicitly specify HLS format for m3u8 urls
    );

    try {
      await controller.initialize();
      controller.setLooping(true);
      state = controller;
    } catch (e) {
      print("Error initializing video: $e");
    }
  }

  void setMuted(bool isMuted) {
    state?.setVolume(isMuted ? 0.0 : 1.0);
  }

  void play() {
    state?.play();
  }

  void pause() {
    state?.pause();
  }

  @override
  void dispose() {
    state?.pause();
    state?.dispose();
    state = null;
    super.dispose();
  }
}

// A provider family that creates a unique provider for each video ID
final videoControllerProvider = StateNotifierProvider.family<
    VideoControllerNotifier, VideoPlayerController?, String>(
  (ref, videoId) {
    final controllers = ref.watch(activeVideoControllersProvider);

    // Get the URL for this video ID
    final url = controllers[videoId]?.dataSource ?? '';
    return VideoControllerNotifier(url, videoId);
  },
);

class VideoPost extends ConsumerStatefulWidget {
  final String videoUrl;
  final String postId;
  final int index;
  final String? thumbnailUrl; // Optional thumbnail URL

  const VideoPost({
    super.key,
    required this.videoUrl,
    required this.postId,
    required this.index,
    this.thumbnailUrl,
  });

  @override
  ConsumerState<VideoPost> createState() => _VideoPostState();
}

class _VideoPostState extends ConsumerState<VideoPost> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isVisible = false;
  bool _isBuffering = false;
  double _loadingProgress = 0.0;
  bool _isMounted = false;
  String get _videoId => "${widget.postId}-${widget.index}";
  bool get _isHlsStream => widget.videoUrl.toLowerCase().endsWith('.m3u8');

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _initializeController();
  }

  Future<void> _initializeController() async {
    // Create the controller with the formatHint option for HLS streams
    _controller = VideoPlayerController.network(
      widget.videoUrl,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      formatHint: _isHlsStream ? VideoFormat.hls : null,
    );

    _controller.addListener(_videoListener);

    try {
      await _controller.initialize();
      _controller.setLooping(true);

      // Update active controllers map
      final currentControllers = ref.read(activeVideoControllersProvider);
      ref.read(activeVideoControllersProvider.notifier).state = {
        ...currentControllers,
        _videoId: _controller
      };

      // Apply global mute state
      final isMuted = ref.read(audioProvider).isMuted;
      _controller.setVolume(isMuted ? 0.0 : 1.0);

      if (_isMounted) {
        setState(() {
          _isInitialized = true;

          // Start playing if the video is visible
          if (_isVisible) {
            _playVideo();
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
      if (_isMounted) {
        setState(() {
          _loadingProgress = position.inMilliseconds / duration.inMilliseconds;
        });
      }
    }

    // Check buffering status - especially important for HLS streams
    final bool isBuffering = _controller.value.isBuffering;
    if (_isBuffering != isBuffering && _isMounted) {
      setState(() {
        _isBuffering = isBuffering;
      });
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }

  void _playVideo() {
    if (!_isInitialized) return;

    // Set this as current playing video
    ref.read(currentPlayingVideoProvider.notifier).state = _videoId;

    // Pause other videos
    final controllers = ref.read(activeVideoControllersProvider);
    for (final entry in controllers.entries) {
      if (entry.key != _videoId) {
        entry.value.pause();
      }
    }

    // For HLS streams, we might want to reconsider setting position to beginning
    // when resuming play, as some streams might not support seeking well
    _controller.play();
    if (_isMounted) {
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _pauseVideo() {
    if (!_isInitialized) return;

    _controller.pause();
    if (_isMounted) {
      setState(() {
        _isPlaying = false;
      });
    }

    // Clear current playing if it's this video
    if (ref.read(currentPlayingVideoProvider) == _videoId) {
      ref.read(currentPlayingVideoProvider.notifier).state = null;
    }
  }

  void _toggleMute() {
    final audioNotifier = ref.read(audioProvider.notifier);
    audioNotifier.toggleMute();
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    final isVisible = info.visibleFraction > 0.5;

    if (_isVisible != isVisible) {
      if (_isMounted) {
        setState(() {
          _isVisible = isVisible;
        });
      }

      // Only autoplay if already initialized
      if (_isInitialized) {
        if (_isVisible) {
          _playVideo();
        } else {
          _pauseVideo();
        }
      }
    }
  }

  @override
  void didUpdateWidget(VideoPost oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update controller when URL changes
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeCurrentController();
      _initializeController();
    }
  }

  void _disposeCurrentController() {
    // Remove from active controllers
    final currentControllers = ref.read(activeVideoControllersProvider);
    final newControllers =
        Map<String, VideoPlayerController>.from(currentControllers);
    newControllers.remove(_videoId);
    ref.read(activeVideoControllersProvider.notifier).state = newControllers;

    _controller.removeListener(_videoListener);
    _controller.pause();
    _controller.dispose();
    _isInitialized = false;
    _isPlaying = false;
  }

  @override
  void dispose() {
    _isMounted = false;
    _disposeCurrentController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioProvider);
    final isMuted = audioState.isMuted;

    // Apply global mute state to this video
    if (_isInitialized) {
      _controller.setVolume(isMuted ? 0.0 : 1.0);
    }

    return VisibilityDetector(
      key: Key(_videoId),
      onVisibilityChanged: _handleVisibilityChanged,
      child: AspectRatio(
        aspectRatio: _isInitialized ? _controller.value.aspectRatio : (9 / 16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player
            GestureDetector(
              onTap: _togglePlayPause,
              child: _isInitialized
                  ? FittedBox(
                    fit: BoxFit.contain,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    )
                  : widget.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Colors.black),
                          errorWidget: (context, url, error) =>
                              Container(color: Colors.black),
                        )
                      : Container(color: Colors.black),
            ),

            // Loading indicator
            if (!_isInitialized) const CircularProgressIndicator(),

            // Show buffering indicator for HLS streams
            if (_isInitialized && _isBuffering)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),

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

            // HLS indicator (optional - helps during development)
            if (_isHlsStream && _isInitialized)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.black.withOpacity(0.5),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'HLS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
                      isMuted ? Icons.volume_off : Icons.volume_up,
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
