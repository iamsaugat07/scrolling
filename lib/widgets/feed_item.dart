// ================= widgets/feed_item.dart =================
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import 'text_post.dart';
import 'image_post.dart';
import 'video_post.dart';

class FeedItem extends StatelessWidget {
  final Post post;
  final bool globalMute;
  final Function(bool) onMuteChanged;

  const FeedItem({
    super.key,
    required this.post,
    required this.globalMute,
    required this.onMuteChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          _buildPostContent(),

          // Interaction buttons
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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

  Widget _buildPostContent() {
    switch (post.type) {
      case PostType.text:
        return TextPost(content: post.content ?? '');
      case PostType.image:
        return ImagePost(imageUrl: post.mediaUrl ?? '');
      case PostType.video:
        return VideoPost(
          videoUrl: post.mediaUrl ?? '',
          isMuted: globalMute,
          onMuteChanged: onMuteChanged,
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
