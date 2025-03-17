class MediaData {
  final String idData;
  final String description;
  final String hashtag;
  final String mediaUrl;
  final String profile;
  final String timestamp;
  final String title;
  final String uploadedBy;
  final String userId;
  final String type;
  int likes;
  int isLiked; // 0 = belum like, 1 = sudah like
  bool isBookmarked; // Tambahkan properti bookmark

  MediaData({
    required this.idData,
    required this.description,
    required this.hashtag,
    required this.mediaUrl,
    required this.profile,
    required this.timestamp,
    required this.title,
    required this.uploadedBy,
    required this.userId,
    this.likes = 0,
    this.isLiked = 0, // Default 0 = belum like
    this.isBookmarked = false, // Default false = belum disimpan
    required this.type,
  });

  factory MediaData.fromMap(Map<dynamic, dynamic> data, String currentUserId) {
    // Cek apakah isLiked ada dan berupa Map
    Map<dynamic, dynamic> isLikedMap = data['isLiked'] != null
        ? Map<dynamic, dynamic>.from(data['isLiked'])
        : {};

    // Cek apakah bookmarks ada dan berupa Map
    Map<dynamic, dynamic> bookmarksMap = data['bookmarks'] != null
        ? Map<dynamic, dynamic>.from(data['bookmarks'])
        : {};

    // Tentukan status isLiked dan isBookmarked
    int isCurrentlyLiked = isLikedMap.containsKey(currentUserId) ? 1 : 0;
    bool isCurrentlyBookmarked = bookmarksMap.containsKey(currentUserId);

    return MediaData(
      idData: data['idData'] ?? '',
      description: data['description'] ?? '',
      hashtag: data['hashtag'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
      profile: data['profile'] ?? '',
      timestamp: data['timestamp'] ?? '',
      title: data['title'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      userId: data['userId'] ?? '',
      likes: data['likes'] ?? 0,
      isLiked: isCurrentlyLiked, // Simpan dalam bentuk int
      isBookmarked: isCurrentlyBookmarked, // Simpan dalam bentuk boolean
      type: data['type'] ?? 'image',
    );
  }

  get aspectRatio => null;
}
