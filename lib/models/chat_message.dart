class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? audioUrl;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.audioUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['is_user'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      audioUrl: json['audio_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'audio_url': audioUrl,
    };
  }
}

class Footprint {
  final String spotId;
  final String spotName;
  final DateTime visitedAt;
  final bool hasPlayed;

  const Footprint({
    required this.spotId,
    required this.spotName,
    required this.visitedAt,
    this.hasPlayed = false,
  });

  factory Footprint.fromJson(Map<String, dynamic> json) {
    return Footprint(
      spotId: json['spot_id'] as String,
      spotName: json['spot_name'] as String,
      visitedAt: DateTime.parse(json['visited_at'] as String),
      hasPlayed: json['has_played'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spot_id': spotId,
      'spot_name': spotName,
      'visited_at': visitedAt.toIso8601String(),
      'has_played': hasPlayed,
    };
  }
}