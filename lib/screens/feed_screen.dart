import 'dart:async';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../widgets/feed_item.dart';
import '../services/feed_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  final FeedService _feedService = FeedService();
  final List<Post> _posts = [];
  bool _isLoading = false;
  bool _hasMorePosts = true;
  bool _globalMute = true;
  StreamSubscription? _volumeSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
    _scrollController.addListener(_scrollListener);
    _listenToVolumeChanges();
  }

  void _listenToVolumeChanges() {
    // In a real app, you would implement a platform channel to listen to volume changes
    // This is a simplified example
    _volumeSubscription =
        Stream.periodic(const Duration(seconds: 5)).listen((_) {
      // Check if volume is increased and unmute if needed
      // This would be implemented via platform channels in a real app
    });
  }

  Future<void> _loadInitialPosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newPosts = await _feedService.fetchPosts(0, 10);
      setState(() {
        _posts.addAll(newPosts);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMorePosts) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newPosts = await _feedService.fetchPosts(_posts.length, 10);
      setState(() {
        if (newPosts.isEmpty) {
          _hasMorePosts = false;
        } else {
          _posts.addAll(newPosts);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMorePosts();
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onMuteChanged(bool isMuted) {
    setState(() {
      _globalMute = isMuted;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _volumeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        elevation: 0,
        leading: const Icon(Icons.camera_alt_outlined),
        actions: [
          IconButton(
            icon: Icon(_globalMute ? Icons.volume_off : Icons.volume_up),
            onPressed: () {
              setState(() {
                _globalMute = !_globalMute;
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _posts.clear();
          await _loadInitialPosts();
        },
        child: GestureDetector(
          onTap: () {
            // Check if tap is near the top of the screen
            final RenderBox box = context.findRenderObject() as RenderBox;
            final Offset localPosition = box.globalToLocal(Offset.zero);
            if (localPosition.dy < 50) {
              _scrollToTop();
            }
          },
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _posts.length + 1,
            itemBuilder: (context, index) {
              if (index == _posts.length) {
                return _hasMorePosts
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox();
              }

              return FeedItem(
                post: _posts[index],
                globalMute: _globalMute,
                onMuteChanged: _onMuteChanged,
              );
            },
          ),
        ),
      ),
    );
  }
}
