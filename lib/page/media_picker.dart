import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pixel_nest/page/upload_page.dart';

class MediaPickerPage extends StatefulWidget {
  @override
  _MediaPickerPageState createState() => _MediaPickerPageState();
}

class _MediaPickerPageState extends State<MediaPickerPage> with AutomaticKeepAliveClientMixin {


  @override
  bool get wantKeepAlive => true;

  List<AssetPathEntity> albums = [];
  List<AssetEntity> mediaFiles = [];
  AssetPathEntity? selectedAlbum;
  List<AssetEntity> allMediaFiles = [];
  AssetEntity? latestMedia; // Media terbaru yang sedang dipreview
  String activeFilter = "Semua"; // Filter aktif

  @override
  void initState() {
    super.initState();
    _fetchMedia();
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _fetchMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      final List<AssetPathEntity> result = await PhotoManager.getAssetPathList(
        type: RequestType.image | RequestType.video,
        filterOption: FilterOptionGroup(),
      );
      setState(() {
        albums = result;
        if (albums.isNotEmpty) {
          selectedAlbum = albums.first;
          _fetchMediaFiles(albums.first);
        }
      });
    } else {
      PhotoManager.openSetting();
    }
  }

 Future<void> _fetchMediaFiles(AssetPathEntity album) async {
  final List<AssetEntity> result = await album.getAssetListPaged(
    page: 0,
    size: 1000,
  );
  setState(() {
    allMediaFiles = result;
    mediaFiles = result; // Tampilkan semua media awalnya
    latestMedia = mediaFiles.isNotEmpty ? mediaFiles.first : null;
  });
}


  Future<String?> _getFilePath(AssetEntity media) async {
    final file = await media.file;
    return file?.path;
  }

  void _applyFilter(String filter) {
  setState(() {
    activeFilter = filter;

    if (filter == "Semua") {
      mediaFiles = allMediaFiles; // Tampilkan semua media
    } else if (filter == "Gambar") {
      mediaFiles = allMediaFiles.where((media) => media.type == AssetType.image).toList();
    } else if (filter == "Video") {
      mediaFiles = allMediaFiles.where((media) => media.type == AssetType.video).toList();
    }
  });
}


  @override
  Widget build(BuildContext context) {
    bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    Color backgroundColor = isDarkMode ? Colors.black : Colors.grey[100]!;
    Color textColor = isDarkMode ? Colors.white : Colors.black;
    Color activeColor = isDarkMode ? Colors.amber : Colors.blue;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: isDarkMode ? Colors.black : Colors.white,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      appBar: AppBar(
  backgroundColor: backgroundColor,
  centerTitle: true,
  title: albums.isNotEmpty
      ? DropdownButtonHideUnderline(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8, // Menyesuaikan dengan layar
            child: DropdownButton<AssetPathEntity>(
              isExpanded: true, // Dropdown akan mengambil seluruh lebar
              value: selectedAlbum,
              icon: Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Icon(Icons.arrow_drop_down, color: textColor),
              ),
              dropdownColor: backgroundColor,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'Roboto',
              ),
              items: albums
                  .map((album) => DropdownMenuItem(
                        value: album,
                        child: Text(
                          album.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (album) {
                if (album != null) {
                  setState(() {
                    selectedAlbum = album;
                  });
                  _fetchMediaFiles(album);
                }
              },
            ),
          ),
        )
      : Text(
          'Loading...',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
            fontFamily: 'Roboto',
          ),
        ),
  leading: IconButton(
    icon: Icon(Icons.close, color: textColor),
    onPressed: () {
      Navigator.pop(context);
    },
  ),
),

      body: Container(
        color: backgroundColor,
        child: Column(
          children: [
            // Filter Horizontal
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ["Semua", "Gambar", "Video"].map((filter) {
                  bool isActive = activeFilter == filter;
                  return GestureDetector(
  onTap: () {
    _applyFilter(filter);
  },
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        filter,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
          color: isActive ? activeColor : textColor,
        ),
      ),
      if (isActive)
        Container(
          margin: const EdgeInsets.only(top: 4),
          height: 2,
          width: 40,
          color: activeColor,
        ),
    ],
  ),
);

                }).toList(),
              ),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: mediaFiles.length,
                itemBuilder: (context, index) {
                  final media = mediaFiles[index];
                  return GestureDetector(
                    onTap: () async {
                      if (media.type == AssetType.video && media.duration > 60) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Durasi video tidak boleh lebih dari 1 menit.'),
                          ),
                        );
                        return;
                      }
                      final filePath = await _getFilePath(media);
                      if (filePath != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UploadPage(filePath: filePath),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal mendapatkan file media.'),
                          ),
                        );
                      }
                    },
                    child: FutureBuilder<Uint8List?>(
                      future: media.thumbnailDataWithSize(
                        const ThumbnailSize(200, 200),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              ),
                              if (media.type == AssetType.video) ...[
                                Align(
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _formatDuration(media.duration),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
