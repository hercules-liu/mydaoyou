class Friend {
  final String id;
  final String name;
  final String avatar;
  final Map<String, double>? currentLocation;
  final DateTime? lastUpdate;

  const Friend({
    required this.id,
    required this.name,
    required this.avatar,
    this.currentLocation,
    this.lastUpdate,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      currentLocation: json['current_location'] != null
          ? Map<String, double>.from(json['current_location'])
          : null,
      lastUpdate: json['last_update'] != null
          ? DateTime.parse(json['last_update'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'current_location': currentLocation,
      'last_update': lastUpdate?.toIso8601String(),
    };
  }

  Friend copyWith({
    String? id,
    String? name,
    String? avatar,
    Map<String, double>? currentLocation,
    DateTime? lastUpdate,
  }) {
    return Friend(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      currentLocation: currentLocation ?? this.currentLocation,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  String get lastUpdateText {
    if (lastUpdate == null) return '未知';
    final diff = DateTime.now().difference(lastUpdate!);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}

class Comment {
  final String id;
  final String spotId;
  final String spotName;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final double rating;
  final List<String> images;
  final DateTime createdAt;
  final int likeCount;
  final bool isLiked;

  const Comment({
    required this.id,
    required this.spotId,
    required this.spotName,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.rating,
    this.images = const [],
    required this.createdAt,
    this.likeCount = 0,
    this.isLiked = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      spotId: json['spot_id'] as String,
      spotName: json['spot_name'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userAvatar: json['user_avatar'] as String,
      content: json['content'] as String,
      rating: (json['rating'] as num).toDouble(),
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      likeCount: json['like_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spot_id': spotId,
      'spot_name': spotName,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'content': content,
      'rating': rating,
      'images': images,
      'created_at': createdAt.toIso8601String(),
      'like_count': likeCount,
      'is_liked': isLiked,
    };
  }

  Comment copyWith({
    String? id,
    String? spotId,
    String? spotName,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    double? rating,
    List<String>? images,
    DateTime? createdAt,
    int? likeCount,
    bool? isLiked,
  }) {
    return Comment(
      id: id ?? this.id,
      spotId: spotId ?? this.spotId,
      spotName: spotName ?? this.spotName,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      rating: rating ?? this.rating,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}