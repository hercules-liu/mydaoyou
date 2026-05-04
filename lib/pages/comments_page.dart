import 'package:flutter/material.dart';
import '../services/comment_service.dart';
import '../models/friend.dart';
import '../models/scenic_spot.dart';

class CommentsPage extends StatefulWidget {
  final ScenicSpot? spot;

  const CommentsPage({super.key, this.spot});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final CommentService _commentService = CommentService();

  List<Comment> _comments = [];
  bool _isLoading = true;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);

    await _commentService.init();
    final comments = widget.spot != null
        ? await _commentService.getCommentsBySpot(widget.spot!.id)
        : await _getAllComments();
    final avgRating = widget.spot != null
        ? await _commentService.getAverageRating(widget.spot!.id)
        : 0.0;

    setState(() {
      _comments = comments;
      _averageRating = avgRating;
      _isLoading = false;
    });
  }

  Future<List<Comment>> _getAllComments() async {
    final allComments = <Comment>[];
    for (final spot in ['spot_001', 'spot_002', 'spot_003']) {
      final comments = await _commentService.getCommentsBySpot(spot);
      allComments.addAll(comments);
    }
    allComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allComments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.spot?.name ?? '好友点评'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadComments,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCommentDialog,
        icon: const Icon(Icons.edit),
        label: const Text('写点评'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无点评',
              style: TextStyle(fontSize: 18, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              '成为第一个点评的人吧',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildRatingSummary(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              return _buildCommentCard(_comments[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                _averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < _averageRating.round()
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.yellow,
                    size: 20,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${_comments.length}条点评',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              children: [5.0, 4.0, 3.0, 2.0, 1.0].map((rating) {
                final count = _comments.where((c) => c.rating == rating).length;
                final percentage = _comments.isEmpty
                    ? 0.0
                    : count / _comments.length;
                return _buildRatingBar(rating.toInt(), percentage);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const Icon(Icons.star, color: Colors.yellow, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellow),
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundImage: NetworkImage(comment.userAvatar),
              onBackgroundImageError: (_, __) {},
            ),
            title: Text(
              comment.userName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < comment.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  _formatTime(comment.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                comment.isLiked ? Icons.favorite : Icons.favorite_border,
                color: comment.isLiked ? Colors.red : Colors.grey,
              ),
              onPressed: () async {
                await _commentService.likeComment(comment.id);
                _loadComments();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              comment.content,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
          if (comment.images.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                itemCount: comment.images.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(comment.images[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  comment.spotName,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const Spacer(),
                Icon(Icons.thumb_up_outlined, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  '${comment.likeCount}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    return '${time.month}/${time.day}';
  }

  void _showAddCommentDialog() {
    if (widget.spot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个景点')),
      );
      return;
    }

    final contentController = TextEditingController();
    double selectedRating = 5.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '评价 ${widget.spot!.name}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('评分'),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setModalState(() => selectedRating = (index + 1).toDouble());
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  const Text('点评内容'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: '分享您的游览体验...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (contentController.text.isNotEmpty) {
                          await _commentService.addComment(
                            spotId: widget.spot!.id,
                            spotName: widget.spot!.name,
                            content: contentController.text,
                            rating: selectedRating,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            _loadComments();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('发布点评'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}