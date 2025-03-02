import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reelscroll/provider/audio_provider.dart';
import 'package:reelscroll/provider/feed_provider.dart';

import '../widgets/feed_item.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _volumeSubscription;

  @override
  void initState() {
    super.initState();
    // Load initial posts on screen creation
    Future.microtask(() => ref.read(feedProvider.notifier).loadInitialPosts());
    _scrollController.addListener(_scrollListener);
    _listenToVolumeChanges();
  }

  void _listenToVolumeChanges() {
    // In a real app, you would implement a platform channel to listen to volume changes
    // This is a simplified example
    _volumeSubscription = Stream.periodic(const Duration(seconds: 5)).listen((_) {
      // Check if volume is increased and unmute if needed
      // This would be implemented via platform channels in a real app
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      ref.read(feedProvider.notifier).loadMorePosts();
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _volumeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final audioState = ref.watch(audioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        elevation: 0,
        leading: const Icon(Icons.camera_alt_outlined),
        actions: [
          IconButton(
            icon: Icon(audioState.isMuted ? Icons.volume_off : Icons.volume_up),
            onPressed: () {
              ref.read(audioProvider.notifier).toggleMute();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(feedProvider.notifier).clearPosts();
          await ref.read(feedProvider.notifier).loadInitialPosts();
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
          child: feedState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${feedState.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(feedProvider.notifier).loadInitialPosts(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : feedState.posts.isEmpty && feedState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: feedState.posts.length + 1,
                      itemBuilder: (context, index) {
                        if (index == feedState.posts.length) {
                          return feedState.hasMore
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox();
                        }
                        
                        return FeedItem(
                          post: feedState.posts[index],
                          index: index,
                        );
                      },
                    ),
        ),
      ),
    );
  }
}