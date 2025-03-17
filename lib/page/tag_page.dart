import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pixel_nest/models/media_data.dart';
import 'package:pixel_nest/page/image_detail_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

class TagPage extends StatefulWidget {
  final String hashtag;

  const TagPage({Key? key, required this.hashtag}) : super(key: key);

  @override
  _TagPageState createState() => _TagPageState();
}

class _TagPageState extends State<TagPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late DatabaseReference _databaseReference;
  List<MediaData> mediaPaths = [];
  bool _isShimmerVisible = true;

  @override
  void initState() {
    super.initState();
    _databaseReference = FirebaseDatabase.instance.ref().child("uploads");
    _fetchTaggedMedia();
  }

  void _fetchTaggedMedia() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
final String currentUserId = user?.uid ?? '';

      DataSnapshot snapshot = await _databaseReference.get();
      if (snapshot.exists) {
        List<MediaData> mediaList = [];
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        for (var key in values.keys) {
         final mediaData = MediaData.fromMap(values[key], currentUserId);

          String postHashtag = mediaData.hashtag.replaceAll("#", "").toLowerCase();
          String selectedHashtag = widget.hashtag.replaceAll("#", "").toLowerCase();
          if (postHashtag == selectedHashtag) {
            mediaList.add(mediaData);
          }
        }
        setState(() {
          mediaPaths = mediaList;
          _isShimmerVisible = false;
        });
      } else {
        setState(() {
          _isShimmerVisible = false;
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        _isShimmerVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Menentukan apakah menggunakan mode gelap atau terang
    final brightness = MediaQuery.of(context).platformBrightness;
    final backgroundColor = brightness == Brightness.dark ? Colors.black : Colors.white;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    Color textColor = isDarkMode ? const Color.fromARGB(255, 228, 160, 160) : Colors.black;

    return Scaffold(
  appBar: AppBar(
  title: Text(
    "#${widget.hashtag}",
    style: TextStyle(color: brightness == Brightness.dark ? Colors.white : Colors.black,fontFamily: 'Poppins',
               ),
  ),
  backgroundColor: backgroundColor,
  elevation: 0, // Menghilangkan bayangan
  leading: IconButton(
    icon: Icon(Icons.arrow_back, color: brightness == Brightness.dark ? Colors.white : Colors.black),
    onPressed: () => Navigator.pop(context),
  ),
),

  backgroundColor: backgroundColor, // Tambahkan ini
  body: Padding(
    padding: const EdgeInsets.all(8.0),
    child: MasonryGridView.builder(
      itemCount: _isShimmerVisible ? 9 : mediaPaths.length,
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemBuilder: (BuildContext context, int index) {
        if (_isShimmerVisible) {
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Shimmer.fromColors(
                baseColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300, // Sesuaikan warna shimmer
                highlightColor: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade100,
                child: Container(
                  color: backgroundColor, // Sesuaikan latar belakang shimmer
                  width: double.infinity,
                  height: 180 + Random().nextInt(120).toDouble(),
                ),
              ),
            ),
          );
        }
        MediaData mediaData = mediaPaths[index];
        bool isVideo = mediaData.type == 'video';
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ImageDetailPage(mediaData: mediaData),
                  ),
                );
              },
              child: isVideo
                  ? VideoPlayerWidget(videoUrl: mediaData.mediaUrl)
                  : CachedNetworkImage(
                      imageUrl: mediaData.mediaUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                        highlightColor: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade100,
                        child: Container(
                          color: isDarkMode ? Colors.grey.shade900 : Colors.white, // Sesuaikan warna shimmer
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
);

  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
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