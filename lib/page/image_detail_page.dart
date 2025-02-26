import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:path_provider/path_provider.dart';
import 'package:pixel_nest/page/tag_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:pixel_nest/models/media_data.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:permission_handler/permission_handler.dart';


class ImageDetailPage extends StatefulWidget {
  final MediaData mediaData;
  

  const ImageDetailPage({super.key, required this.mediaData});

  @override
  _ImageDetailPageState createState() => _ImageDetailPageState();
}

class _ImageDetailPageState extends State<ImageDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late VideoPlayerController? _videoController;
  bool isVideo = false;
  bool isLoading = true;
  List<MediaData> relatedPosts = [];
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0))
            .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    setState(() {
      isLoading = true;
    });

    String mediaUrl = widget.mediaData.mediaUrl;
     isVideo = widget.mediaData.type.contains('video');

    if (isVideo) {
      _videoController = VideoPlayerController.network(mediaUrl)
        ..initialize().then((_) {
          setState(() {
            isLoading = false;
          });
          _videoController?.setLooping(true);
          _videoController?.play();
        });
    } else {
      Image.network(
        mediaUrl,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            setState(() {
              isLoading = false;
            });
            return child;
          }
          return const CircularProgressIndicator();
        },
      );
    }

    _fetchRelatedPosts();
  }

  Future<void> _downloadMedia(String url) async {
  try {
    // 🔹 Cek izin penyimpanan terlebih dahulu
    bool hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      print("Izin penyimpanan tidak diberikan.");
      return;
    }

    // 🔹 Ambil referensi file dari Firebase Storage
    Reference ref = FirebaseStorage.instance.refFromURL(url);

    // 🔹 Tentukan lokasi penyimpanan
    Directory? directory = await getExternalStorageDirectory();
    if (directory == null) {
      print("Gagal mendapatkan direktori penyimpanan.");
      return;
    }

    String filePath = "${directory.path}/${ref.name}";

    // 🔹 Unduh file ke penyimpanan lokal
    File downloadToFile = File(filePath);
    await ref.writeToFile(downloadToFile);

    print("Unduhan selesai: $filePath");
 
  } catch (e) {
    print("Gagal mengunduh file: $e");
  }
}


// Fungsi untuk meminta izin penyimpanan
Future<bool> _requestStoragePermission() async {
  if (Platform.isAndroid) {
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }
    if (await Permission.storage.request().isGranted) {
      return true;
    }
  }
  return false;
}

  



// Fungsi untuk memulai proses download
void _startDownload(String url) async {
  Directory? directory;

  if (Platform.isAndroid) {
    if (await Permission.storage.request().isGranted) {
      directory = Directory('/storage/emulated/0/Download');
    } else {
      print("Izin penyimpanan tidak diberikan!");
      return;
    }
  } else {
    directory = await getApplicationDocumentsDirectory();
  }

  if (directory == null) {
    print("Gagal mendapatkan direktori penyimpanan.");
    return;
  }

  // 🔹 Ambil nama file dari URL
  String fileName = Uri.parse(url).pathSegments.last.split('?').first;
  
  final taskId = await FlutterDownloader.enqueue(
    url: url,
    savedDir: directory.path,
    fileName: fileName,
    showNotification: true,
    openFileFromNotification: true,
  );

  if (taskId != null) {
    print("Unduhan dimulai: ${directory.path}/$fileName");
  } else {
    print("Gagal memulai unduhan.");
  }
}








  void _fetchRelatedPosts() async {
  final databaseReference = FirebaseDatabase.instance.ref();
  DataSnapshot snapshot = await databaseReference.child("uploads").get();

  if (snapshot.exists) {
    List<MediaData> posts = [];
    var data = snapshot.value as Map;
    String currentMediaUrl = widget.mediaData.mediaUrl;
    String currentHashtag = widget.mediaData.hashtag;

    // Ambil user yang sedang login
    final User? user = FirebaseAuth.instance.currentUser;
    final String currentUserId = user?.uid ?? '';

    data.forEach((key, value) {
      // Gunakan currentUserId saat memanggil fromMap
      MediaData post = MediaData.fromMap(value, currentUserId);

      if (post.hashtag == currentHashtag &&
          post.mediaUrl != currentMediaUrl) {
        posts.add(post);
      }
    });

    setState(() {
      relatedPosts = posts;
    });
  }
}


  Future<void> _deleteMedia(String idData) async {
  try {
    // 🔹 Referensi ke 'uploads' di Firebase Realtime Database
    final databaseReference = FirebaseDatabase.instance.ref().child("uploads");

    // 🔹 Ambil semua data dari 'uploads'
    final snapshot = await databaseReference.get();

    if (snapshot.exists) {
      bool found = false;

      // 🔹 Loop untuk mencari idData yang cocok
      for (var item in snapshot.children) {
        final itemData = item.value as Map<dynamic, dynamic>;

        // Cek apakah idData cocok
        if (itemData['idData'] == idData) {
          found = true;

          // Hapus data dari Realtime Database
          await item.ref.remove();
          print("Item berhasil dihapus dari Realtime Database");

          // Hapus file dari Firebase Storage
          Reference ref = FirebaseStorage.instance.refFromURL(itemData['mediaUrl']);
          await ref.delete();
          print("File berhasil dihapus dari Firebase Storage");

          // Redirect ke halaman sebelumnya
          if (mounted) {
  Navigator.pop(context, true); 
}
          break;
        }
      }

      if (!found) {
        print("Item tidak ditemukan di Realtime Database");
      }
    } else {
      print("Tidak ada data di Realtime Database");
    }
  } catch (e) {
    print("Gagal menghapus item: $e");
  }
}





 void _toggleLike() async {
  final User? user = FirebaseAuth.instance.currentUser;
  final String userId = user?.uid ?? ''; // Ambil UID dari Firebase Auth

  // Cek apakah user sudah login
  if (userId.isEmpty) {
    print("User belum login.");
    return;
  }

  final databaseReference = FirebaseDatabase.instance.ref();
  String idData = widget.mediaData.idData;

  DatabaseReference mediaRef = databaseReference.child("uploads").child(idData);

  // Ambil data isLiked dari Firebase
  DataSnapshot snapshot = await mediaRef.child('isLiked').get();
  Map<dynamic, dynamic> isLikedMap = snapshot.value != null
      ? Map<dynamic, dynamic>.from(snapshot.value as Map)
      : {};

  // Cek apakah user sudah like atau belum
  int isCurrentlyLiked = isLikedMap[userId] ?? 0;

  // Update isLiked dan likes
  if (isCurrentlyLiked == 1) {
    // Jika sudah like, maka unlike
    isLikedMap.remove(userId);
  } else {
    // Jika belum like, maka like
    isLikedMap[userId] = 1;
  }

  // Hitung total likes berdasarkan jumlah key di dalam isLiked
  int totalLikes = isLikedMap.length;

  await mediaRef.update({
    'isLiked': isLikedMap,
    'likes': totalLikes,
  });

  // Update status lokal setelah update di Firebase
  setState(() {
    widget.mediaData.isLiked = isCurrentlyLiked == 1 ? 0 : 1;
    widget.mediaData.likes = totalLikes;
  });
}








  @override
  void dispose() {
    _animationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    Color backgroundColor = isDarkMode ? Colors.black : Colors.grey[100]!;
    Color textColor = isDarkMode ? Colors.white : Colors.black;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: backgroundColor,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    String title = widget.mediaData.title;
    String description = widget.mediaData.description;
    String uploadedBy = widget.mediaData.uploadedBy;

    return Scaffold(
      backgroundColor: backgroundColor,
       body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                // Media display
                Padding(
                  padding: const EdgeInsets.only(top: 28.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isLoading)
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              isDarkMode ? Colors.white : Colors.black),
                        ),
                        
                      if (isVideo)
                        _videoController != null &&
                                _videoController!.value.isInitialized
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AspectRatio(
                                    aspectRatio:
                                        _videoController!.value.aspectRatio,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink()
                      else
                        GestureDetector(
                          onTap: () => _showFullScreenMedia(context),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.mediaData.mediaUrl,
                                fit: BoxFit.contain,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  }
                                  return CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        isDarkMode
                                            ? Colors.white
                                            : Colors.black),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey
                                .withOpacity(0.6), // Gray background color
                          ),
                          padding: const EdgeInsets.all(0.5), // Circle padding
                          child: IconButton(
                            icon: Icon(Icons.chevron_left, color: Colors.black),
                            onPressed: () => Navigator.of(context).pop(),
                            iconSize: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
Padding(
  padding: const EdgeInsets.all(8.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      // Ikon Love dan teks
      // Tombol Like dan Jumlah Like
Padding(
  padding: const EdgeInsets.all(8.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(right: 20.0), // Spasi antara ikon dan teks
        child: Row(
          children: [
         IconButton(
  icon: Icon(
    widget.mediaData.isLiked == 1
        ? Icons.favorite
        : Icons.favorite_border,
    color: widget.mediaData.isLiked == 1
        ? Colors.red
        : MediaQuery.of(context).platformBrightness == Brightness.dark
            ? Colors.white
            : Colors.black,
  ),
  padding: EdgeInsets.zero, // Menghilangkan padding bawaan
  visualDensity: VisualDensity.compact, // Memperkecil ruang sekitar ikon
  iconSize: 28.0,
  onPressed: _toggleLike,
),


const SizedBox(width: 0),
           
            Text(
              widget.mediaData.likes.toString(), // Menampilkan jumlah like
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontFamily: 'Poppins',
              ),
            ),
         ],
        ),
      ),
    ],
  ), 
),

      // Ikon Komentar dan teks
      Padding(
  padding: const EdgeInsets.only(right: 15.0), // Spasi antara ikon dan teks
  child: Row(
    children: [
      Image.asset(
        MediaQuery.of(context).platformBrightness == Brightness.dark
            ? 'assets/images/chat_white.png'
            : 'assets/images/chat.png',
        width: 22.0,
        height: 22.0,
        color: null, // Mencegah pewarnaan otomatis
      ),
      const SizedBox(width: 6),
      Text(
        "0", // Teks yang ditambahkan
        style: TextStyle(
          color: textColor,
          fontSize: 17,
          fontFamily: 'Poppins',
        ),
      ),
    ],
  ),
),



Padding(
  padding: const EdgeInsets.only(right: 130.0),
  child: Row(
    children: [
      PopupMenuButton<String>(
  icon: Icon(
          Icons.more_horiz,
          color: MediaQuery.of(context).platformBrightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          size: 35.0, // Atur ukuran ikon
        ),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  onSelected: (value) {
    if (value == 'download') {
      _downloadMedia(widget.mediaData.mediaUrl);
    } else if (value == 'hapus') {
      showDialog(
        context: context,
        builder: (context) {
          bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: isDarkMode ? Colors.orange : Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Konfirmasi Hapus',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            content: Text(
              'Apakah Anda yakin ingin menghapus item ini?',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Roboto',
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: isDarkMode ? Colors.blue[200] : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteMedia(widget.mediaData.idData);

                  // Tampilkan SnackBar setelah penghapusan berhasil
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Media berhasil dihapus!'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Hapus',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      );
    }
  },
  itemBuilder: (context) {
    bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return [
      PopupMenuItem(
        value: 'download',
        child: Row(
          children: [
            Icon(Icons.download, color: Colors.blue),
            const SizedBox(width: 10),
            Text(
              "Download",
              style: TextStyle(
                color: isDarkMode ? Colors.black : Colors.white,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      if (widget.mediaData.userId == currentUserId)
        PopupMenuItem(
          value: 'hapus',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              const SizedBox(width: 10),
              Text(
                "Hapus",
                style: TextStyle(
                  color: isDarkMode ? Colors.black : Colors.white,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
    ];
  },
  color: MediaQuery.of(context).platformBrightness == Brightness.dark
      ? Colors.white
      : Colors.black,
),
    ],
  ),// Spasi antara ikon dan teks
),

Padding(
  padding: const EdgeInsets.all(8.0),
  child: Icon(
    Icons.bookmark_border,
    color: MediaQuery.of(context).platformBrightness == Brightness.dark
        ? Colors.white
        : Colors.black,
    size: 33.0,
  ),
),



    ],
  ),
),


                // UI untuk data lainnya
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                  child: Align(
                    alignment:
                        Alignment.centerLeft, // Menentukan agar teks rata kiri
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Pastikan teks di kiri
                      children: [
                     ListTile(
  contentPadding: EdgeInsets.zero, // Hilangkan padding bawaan
  leading: CircleAvatar(
    radius: 15, // Sesuaikan ukuran avatar
    backgroundImage: AssetImage('assets/images/2.jpg'),
  ),
  title: Text(
    uploadedBy,
    style: TextStyle(
      fontFamily: 'Poppins',
      color: textColor,
      fontSize: 15, // Sesuaikan ukuran title
      fontWeight: FontWeight.bold,
    ),
  ),
),


                        SizedBox(height: 16),
                        Padding(
  padding: const  EdgeInsets.only(left: 8.0, right: 8.0),
  child: Text(
    title,
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      fontFamily: 'Poppins',
      color: textColor,
    ),
    textAlign: TextAlign.left,
  ),
),
SizedBox(height: 8),
Padding(
  padding:  const EdgeInsets.only(left: 8.0, right: 8.0),
  child: Text(
    description,
    style: TextStyle(
      fontSize: 16,
      fontFamily: 'Poppins',
      color: textColor,
    ),
    textAlign: TextAlign.left,
  ),
),
SizedBox(height: 8),
Padding(
  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
  child: Wrap(
    children: widget.mediaData.hashtag.split(" ").map((tag) {
      if (tag.startsWith("#")) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TagPage(hashtag: tag.substring(1)),
              ),
            );
          },
          child: Text(
            "$tag ",
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else {
        return Text("$tag ");
      }
    }).toList(),
  ),
),


                        SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),

                // Related Posts
                Padding(
  padding: const EdgeInsets.all(8.0),
  child: MasonryGridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: relatedPosts.isEmpty ? 9 : relatedPosts.length,
    gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
    ),
    itemBuilder: (BuildContext context, int index) {
      if (relatedPosts.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Shimmer.fromColors(
              baseColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
              highlightColor: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade100,
              child: Container(
                color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                width: double.infinity,
                height: 180 + Random().nextInt(120).toDouble(),
              ),
            ),
          ),
        );
      }

      MediaData post = relatedPosts[index];
      bool isPostVideo = post.type.contains('video');

      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ImageDetailPage(mediaData: post),
                ),
              );
            },
            child: isPostVideo
                ? VideoPlayerWidget(mediaUrl: post.mediaUrl)

                : CachedNetworkImage(
                    imageUrl: post.mediaUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                      highlightColor: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade100,
                      child: Container(
                        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Center(child: Icon(Icons.broken_image)),
                  ),
          ),
        ),
      );
    },
  ),
),

              ],
            ),
          ),
        ],
      ),
    
    );
    
  }

  



  void _showFullScreenMedia(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: isVideo
                  ? VideoPlayer(_videoController!)
                  : InteractiveViewer(
                      panEnabled: true,
                      boundaryMargin: const EdgeInsets.all(20),
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: Image.network(
                        widget.mediaData.mediaUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  import(String s) {}
}

class VideoPlayerWidget extends StatefulWidget {
  final String mediaUrl;

  const VideoPlayerWidget({Key? key, required this.mediaUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.mediaUrl)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true); // Loop otomatis saat video selesai
        _controller.setVolume(0.0); // Matikan suara (mute)
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return _isInitialized
        ? Stack(
            alignment: Alignment.bottomRight,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),

              // Indikator durasi berjalan real-time
              Positioned(
                top: 8,
                left: 8,
                child: ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, VideoPlayerValue value, child) {
                    return Text(
                      _formatDuration(value.position),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        backgroundColor: Colors.transparent, // Transparan
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        : Shimmer.fromColors( 
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              height: 180,
            ),
          );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";
  }
}
