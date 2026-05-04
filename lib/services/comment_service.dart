import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/friend.dart';
import 'cache_service.dart';

class CommentService {
  final CacheService _cacheService = CacheService();
  static const String _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.example.com');

  final Map<String, List<Comment>> _commentsBySpot = {};

  Future<void> init() async {
    await _cacheService.init();
  }

  Future<List<Comment>> getCommentsBySpot(String spotId) async {
    if (_commentsBySpot.containsKey(spotId)) {
      return _commentsBySpot[spotId]!;
    }

    final comments = await _fetchCommentsFromServer(spotId);
    _commentsBySpot[spotId] = comments;
    return comments;
  }

  Future<List<Comment>> _fetchCommentsFromServer(String spotId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/comments/$spotId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Comment.fromJson(json)).toList();
      }
    } catch (e) {
      // Return mock data on error
    }
    return _getMockComments(spotId);
  }

  List<Comment> _getMockComments(String spotId) {
    final spotName = _getSpotName(spotId);
    return [
      Comment(
        id: 'comment_001',
        spotId: spotId,
        spotName: spotName,
        userId: 'user_001',
        userName: '旅行达人',
        userAvatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=traveler1',
        content: '这里真的很壮观！建议早上早点来，人少一点拍照效果更好。',
        rating: 4.5,
        images: [
          'https://picsum.photos/200/200?random=1',
          'https://picsum.photos/200/200?random=2',
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        likeCount: 42,
        isLiked: false,
      ),
      Comment(
        id: 'comment_002',
        spotId: spotId,
        spotName: spotName,
        userId: 'user_002',
        userName: '历史爱好者',
        userAvatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=historyfan',
        content: '历史文化底蕴深厚，建议听一下语音讲解，能了解到很多背后的故事。',
        rating: 5.0,
        images: [],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        likeCount: 28,
        isLiked: true,
      ),
      Comment(
        id: 'comment_003',
        spotId: spotId,
        spotName: spotName,
        userId: 'user_003',
        userName: '摄影爱好者',
        userAvatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=photographer',
        content: '最佳拍照点在入口左侧，光线特别好！',
        rating: 4.0,
        images: [
          'https://picsum.photos/200/200?random=3',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        likeCount: 15,
        isLiked: false,
      ),
    ];
  }

  String _getSpotName(String spotId) {
    const names = {
      'spot_001': '故宫',
      'spot_002': '天安门广场',
      'spot_003': '景山公园',
    };
    return names[spotId] ?? '未知景点';
  }

  Future<Comment> addComment({
    required String spotId,
    required String spotName,
    required String content,
    required double rating,
    List<String> images = const [],
  }) async {
    final comment = Comment(
      id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
      spotId: spotId,
      spotName: spotName,
      userId: 'current_user',
      userName: '我',
      userAvatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=me',
      content: content,
      rating: rating,
      images: images,
      createdAt: DateTime.now(),
      likeCount: 0,
      isLiked: false,
    );

    if (_commentsBySpot.containsKey(spotId)) {
      _commentsBySpot[spotId]!.insert(0, comment);
    } else {
      _commentsBySpot[spotId] = [comment];
    }

    return comment;
  }

  Future<void> likeComment(String commentId) async {
    for (final comments in _commentsBySpot.values) {
      final index = comments.indexWhere((c) => c.id == commentId);
      if (index >= 0) {
        final comment = comments[index];
        comments[index] = comment.copyWith(
          isLiked: !comment.isLiked,
          likeCount: comment.isLiked ? comment.likeCount - 1 : comment.likeCount + 1,
        );
        break;
      }
    }
  }

  Future<double> getAverageRating(String spotId) async {
    final comments = await getCommentsBySpot(spotId);
    if (comments.isEmpty) return 0.0;

    final total = comments.fold<double>(0, (sum, c) => sum + c.rating);
    return total / comments.length;
  }

  Future<Map<String, double>> getSpotRatings(List<String> spotIds) async {
    final ratings = <String, double>{};
    for (final spotId in spotIds) {
      ratings[spotId] = await getAverageRating(spotId);
    }
    return ratings;
  }
}