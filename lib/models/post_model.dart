enum PostType { text, image, video }

class Post {
  final String id;
  final PostType type;
  final String? content;
  final String? mediaUrl;
  final String username;
  final String userAvatar;
  final DateTime timestamp;

  Post({
    required this.id,
    required this.type,
    this.content,
    this.mediaUrl,
    required this.username,
    required this.userAvatar,
    required this.timestamp,
  });
}
