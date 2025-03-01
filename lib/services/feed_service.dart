// ================= services/feed_service.dart =================
import 'dart:math';
import '../models/post_model.dart';

class FeedService {
  final Random _random = Random();
  
  // Mock data for demonstration
  final List<String> _usernames = [
    'alexsmith', 'jordan23', 'emma_tech', 'travel_mike', 'photo_lisa'
  ];
  
  final List<String> _avatars = [
    'https://randomuser.me/api/portraits/men/1.jpg',
    'https://randomuser.me/api/portraits/women/2.jpg',
    'https://randomuser.me/api/portraits/men/3.jpg',
    'https://randomuser.me/api/portraits/women/4.jpg',
    'https://randomuser.me/api/portraits/men/5.jpg',
  ];
  
  final List<String> _textContents = [
    'Just had an amazing day at the beach! 🏖️',
    'Working on a new project. Stay tuned for updates!',
    'The weather is perfect today for hiking ⛰️',
    'Just finished reading an incredible book. Highly recommend!',
    'Coffee and code, the perfect combination ☕💻',
  ];
  
  final List<String> _imageUrls = [
    'https://picsum.photos/id/10/800/800',
    'https://picsum.photos/id/11/800/800',
    'https://picsum.photos/id/12/800/800',
    'https://picsum.photos/id/13/800/800',
    'https://picsum.photos/id/14/800/800',
  ];
  
  final List<String> _videoUrls = [
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
  ];

  // Simulate fetching posts from a server
  Future<List<Post>> fetchPosts(int offset, int limit) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Generate posts
    final posts = <Post>[];
    
    for (int i = 0; i < limit; i++) {
      final postId = (offset + i).toString();
      final PostType postType = PostType.values[_random.nextInt(PostType.values.length)];
      final username = _usernames[_random.nextInt(_usernames.length)];
      final avatar = _avatars[_random.nextInt(_avatars.length)];
      
      String? content;
      String? mediaUrl;
      
      switch (postType) {
        case PostType.text:
          content = _textContents[_random.nextInt(_textContents.length)];
          break;
        case PostType.image:
          mediaUrl = _imageUrls[_random.nextInt(_imageUrls.length)];
          break;
        case PostType.video:
          mediaUrl = _videoUrls[_random.nextInt(_videoUrls.length)];
          break;
      }
      
      posts.add(Post(
        id: postId,
        type: postType,
        content: content,
        mediaUrl: mediaUrl,
        username: username,
        userAvatar: avatar,
        timestamp: DateTime.now().subtract(Duration(minutes: _random.nextInt(60 * 24 * 7))),
      ));
    }
    
    return posts;
  }
}
