import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/file.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pixel_nest/page/image_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer package
import 'package:pixel_nest/models/media_data.dart';

class ImagesWidget extends StatefulWidget {
  const ImagesWidget({super.key});

  @override
  State<ImagesWidget> createState() => _ImagesWidgetState();
}

class _ImagesWidgetState extends State<ImagesWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late DatabaseReference _databaseReference;
  late FirebaseStorage _storage;
  List<MediaData> mediaPaths = [];
  bool _isShimmerVisible = true;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _databaseReference = FirebaseDatabase.instance.ref().child('uploads');
    _storage = FirebaseStorage.instance;
    _checkIfDataLoaded();
  }

  void _checkIfDataLoaded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isDataLoaded = prefs.getBool('isDataLoaded');

    if (isDataLoaded == true && mediaPaths.isNotEmpty) {
      setState(() {
        _isShimmerVisible = false;
        _isDataLoaded = true;
      });
    } else {
      _fetchMediaPaths();
    }
  }

  void _fetchMediaPaths() async {
    if (_isDataLoaded) return;
    await _loadDataFromFirebase();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDataLoaded', true);
  }

  Future<void> _loadDataFromFirebase() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
final String currentUserId = user?.uid ?? '';
      DataSnapshot snapshot = await _databaseReference.get();
      if (snapshot.exists) {
        List<MediaData> mediaList = [];
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        for (var key in values.keys) {
          final mediaData = MediaData.fromMap(values[key], currentUserId);

          mediaList.add(mediaData);
        }

        setState(() {
          mediaPaths = mediaList;
          _isShimmerVisible = false;
          _isDataLoaded = true;
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

  Future<void> _refreshMediaPaths() async {
    setState(() {
      mediaPaths.clear();
      _isShimmerVisible = true;
    });
    await _loadDataFromFirebase();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RefreshIndicator(
        onRefresh: _refreshMediaPaths,
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
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      period: const Duration(seconds: 2),
                      child: Container(
                        color: Colors.white,
                        width: double.infinity,
                        height: 180 + Random().nextInt(120).toDouble(),
                      ),
                    ),
                  ),
                );
              }

              MediaData mediaData = mediaPaths[index];
              String path = mediaData.mediaUrl;
              String type = mediaData.type;
              bool isVideo = type == 'video';
              double aspectRatio = 9 / 16;

              return Padding(
                padding: const EdgeInsets.all(4.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GestureDetector(
                 onTap: () async {
  final result = await Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ImageDetailPage(mediaData: mediaData),
      transitionsBuilder:
          (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
            position: offsetAnimation, child: child);
      },
    ),
  );

  if (result == true) {
    setState(() {
      _refreshMediaPaths();
    });
  }
},

                 child: isVideo
    ? VideoPlayerWidget(videoPath: path) // Gunakan widget yang diperbarui
    :  CachedNetworkImage(
                          imageUrl: path,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              color: Colors.white,
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
  final String videoPath;

  const VideoPlayerWidget({Key? key, required this.videoPath}) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  double? aspectRatio;
  late File videoFile;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final file = await DefaultCacheManager().getSingleFile(widget.videoPath);
    videoFile = file;
    _controller = VideoPlayerController.file(file)
      ..initialize().then((_) {
        setState(() {
          aspectRatio = _controller.value.aspectRatio;
        });
        _controller.play();
      });

    _controller.setLooping(true);
    _controller.setVolume(0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return aspectRatio == null
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              VisibilityDetector(
                key: Key(widget.videoPath),
                onVisibilityChanged: (visibilityInfo) {
                  final visiblePercentage = visibilityInfo.visibleFraction;
                  if (visiblePercentage > 0) {
                    _controller.play();
                  } else {
                    _controller.pause();
                  }
                },
                child: AspectRatio(
                  aspectRatio: aspectRatio!,
                  child: VideoPlayer(_controller),
                ),
              ),

              // Durasi berjalan real-time di pojok kiri atas dengan background transparan
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
                        backgroundColor: Colors.transparent, // Background transparan
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";
  }
}