import 'dart:math'; 
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/file.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pixel_nest/page/image_detail_page.dart';
import 'package:pixel_nest/models/media_data.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shimmer/shimmer.dart';

class SearchResultPage extends StatelessWidget {
  final List<MediaData> searchResults;
  final String initialQuery; // Tambahkan ini

  const SearchResultPage({
    Key? key,
    required this.searchResults,
    required this.initialQuery, // Tambahkan ini
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final backgroundColor = brightness == Brightness.dark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor, // Sesuai tema
        elevation: 0, // Hilangkan bayangan
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue), // Ikon back
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Hasil Pencarian: $initialQuery",
          style: const TextStyle(color: Colors.blue, fontFamily: 'Poppins',),
        ),
      ),
      body: MasonryGridView.builder(
        itemCount: searchResults.length,
        gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemBuilder: (BuildContext context, int index) {
          MediaData mediaData = searchResults[index];
          String path = mediaData.mediaUrl;
          String type = mediaData.type;
          bool isVideo = type == 'video';

          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
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

                        return SlideTransition(position: offsetAnimation, child: child);
                      },
                    ),
                  );
                },
                child: isVideo
                    ? VideoPlayerWidget(videoPath: path)
                    : CachedNetworkImage(
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
                        errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image)),
                      ),
              ),
            ),
          );
        },
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
