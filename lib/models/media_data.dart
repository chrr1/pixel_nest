class MediaData {
  final String idData; 
  final String description;
  final String hashtag;
  final String mediaUrl;
  final String timestamp;
  final String title;
  final String uploadedBy;
  final String userId;
  final String type;
  int likes;
  int isLiked; // Ganti bool jadi int

  MediaData({
    required this.idData, 
    required this.description,
    required this.hashtag,
    required this.mediaUrl,
    required this.timestamp,
    required this.title,
    required this.uploadedBy,
    required this.userId,
    this.likes = 0,
    this.isLiked = 0, // Default 0 = belum like
    required this.type,
  });

  factory MediaData.fromMap(Map<dynamic, dynamic> data, String currentUserId) {
    // Cek apakah isLiked ada dan berupa Map
    Map<dynamic, dynamic> isLikedMap = data['isLiked'] != null
        ? Map<dynamic, dynamic>.from(data['isLiked'])
        : {};

    // Tentukan isLiked berdasarkan apakah User ID yang sedang login ada di dalam Map
    int isCurrentlyLiked = isLikedMap.containsKey(currentUserId) ? 1 : 0;

    return MediaData(
      idData: data['idData'] ?? '', 
      description: data['description'] ?? '',
      hashtag: data['hashtag'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
      timestamp: data['timestamp'] ?? '',
      title: data['title'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      userId: data['userId'] ?? '',
      likes: data['likes'] ?? 0,
      isLiked: isCurrentlyLiked, // Simpan dalam bentuk int
      type: data['type'] ?? 'image',
    );
  }

  get aspectRatio => null;
}
