/// Model video - ánh xạ từ Firestore collection "videos"
/// Port từ Video.java trong Android project
class VideoModel {
  final String videoId;
  final String videoUri;
  final String authorId;
  final String username;
  final String description;
  final String moderationStatus;
  final int totalLikes;
  final int totalComments;
  final int watchCount;
  final int timestamp;
  final List<String> hashtags;
  final String? location;
  final bool allowDownload;
  final bool allowDuet;
  final bool isCopyrightProtected;

  VideoModel({
    required this.videoId,
    required this.videoUri,
    required this.authorId,
    this.username = '',
    this.description = '',
    this.moderationStatus = 'pending',
    this.totalLikes = 0,
    this.totalComments = 0,
    this.watchCount = 0,
    required this.timestamp,
    this.hashtags = const [],
    this.location,
    this.allowDownload = true,
    this.allowDuet = true,
    this.isCopyrightProtected = false,
  });

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      videoId: map['videoId'] as String? ?? '',
      videoUri: map['videoUri'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      username: map['username'] as String? ?? '',
      description: map['description'] as String? ?? '',
      moderationStatus: map['moderationStatus'] as String? ?? 'pending',
      totalLikes: (map['totalLikes'] as num?)?.toInt() ?? 0,
      totalComments: (map['totalComments'] as num?)?.toInt() ?? 0,
      watchCount: (map['watchCount'] as num?)?.toInt() ?? 0,
      timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
      hashtags: (map['hashtags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      location: map['location'] as String?,
      allowDownload: map['allowDownload'] as bool? ?? true,
      allowDuet: map['allowDuet'] as bool? ?? true,
      isCopyrightProtected: map['isCopyrightProtected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'videoId': videoId,
        'videoUri': videoUri,
        'authorId': authorId,
        'username': username,
        'description': description,
        'moderationStatus': moderationStatus,
        'totalComments': totalComments,
        'totalLikes': totalLikes,
        'watchCount': watchCount,
        'timestamp': timestamp,
        'hashtags': hashtags,
        'location': location,
        'allowDownload': allowDownload,
        'allowDuet': allowDuet,
        'isCopyrightProtected': isCopyrightProtected,
      };

  VideoModel copyWith({
    String? videoId,
    String? videoUri,
    String? authorId,
    String? username,
    String? description,
    String? moderationStatus,
    int? totalLikes,
    int? totalComments,
    int? watchCount,
    int? timestamp,
    List<String>? hashtags,
    String? location,
    bool? allowDownload,
    bool? allowDuet,
    bool? isCopyrightProtected,
  }) {
    return VideoModel(
      videoId: videoId ?? this.videoId,
      videoUri: videoUri ?? this.videoUri,
      authorId: authorId ?? this.authorId,
      username: username ?? this.username,
      description: description ?? this.description,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      totalLikes: totalLikes ?? this.totalLikes,
      totalComments: totalComments ?? this.totalComments,
      watchCount: watchCount ?? this.watchCount,
      timestamp: timestamp ?? this.timestamp,
      hashtags: hashtags ?? this.hashtags,
      location: location ?? this.location,
      allowDownload: allowDownload ?? this.allowDownload,
      allowDuet: allowDuet ?? this.allowDuet,
      isCopyrightProtected: isCopyrightProtected ?? this.isCopyrightProtected,
    );
  }
}
