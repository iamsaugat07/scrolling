import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/post_model.dart';
import '../services/feed_service.dart';

final feedServiceProvider = Provider<FeedService>((ref) {
  return FeedService();
});

// State class for feed
class FeedState {
  final List<Post> posts;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  FeedState({
    required this.posts,
    required this.isLoading,
    required this.hasMore,
    this.error,
  });

  FeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  final FeedService _feedService;
  
  FeedNotifier(this._feedService)
      : super(FeedState(
          posts: [],
          isLoading: false,
          hasMore: true,
          error: null,
        ));

  Future<void> loadInitialPosts() async {
    if (state.isLoading) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final newPosts = await _feedService.fetchPosts(0, 10);
      state = state.copyWith(
        posts: newPosts,
        isLoading: false,
        hasMore: newPosts.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMorePosts() async {
    if (state.isLoading || !state.hasMore) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final newPosts = await _feedService.fetchPosts(state.posts.length, 10);
      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoading: false,
        hasMore: newPosts.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearPosts() {
    state = state.copyWith(posts: [], hasMore: true);
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final feedService = ref.watch(feedServiceProvider);
  return FeedNotifier(feedService);
});