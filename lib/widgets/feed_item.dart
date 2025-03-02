import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/post_model.dart';
import 'text_post.dart';
import 'image_post.dart';
import 'video_post.dart';

class FeedItem extends ConsumerWidget {
  final Post post;
  final int index;

  const FeedItem({
    super.key,
    required this.post,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(post.userAvatar),
                  radius: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  post.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  _getTimeAgo(post.timestamp),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Post content
          _buildPostContent(post, index, ref),
          
          // Interaction buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.favorite_border),
                const SizedBox(width: 16),
                const Icon(Icons.chat_bubble_outline),
                const SizedBox(width: 16),
                const Icon(Icons.send),
                const Spacer(),
                const Icon(Icons.bookmark_border),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent(Post post, int index, WidgetRef ref) {
    switch (post.type) {
      case PostType.text:
        return TextPost(content: post.content ?? '');
      case PostType.image:
        return ImagePost(imageUrl: post.mediaUrl ?? '');
      case PostType.video:
        return VideoPost(
          videoUrl: post.mediaUrl ?? '',
          postId: post.id,
          index: index,
        );
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}