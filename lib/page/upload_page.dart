import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:pixel_nest/page/profile_page.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class UploadPage extends StatefulWidget {
  final String? filePath;

  const UploadPage({super.key, this.filePath});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> with AutomaticKeepAliveClientMixin{
  String? _mediaType;
  String? _profileImage;


  @override
  bool get wantKeepAlive => true;

  VideoPlayerController? _videoController;
  Image? _image;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();

  bool _isUploading = false; // Menandakan proses upload sedang berlangsung
  double _uploadProgress = 0.0; // Menyimpan progres upload dalam persen (0.0 - 1.0)

  @override
  void initState() {
    super.initState();
    if (widget.filePath != null) {
      _initializeMedia();
    }

     _fetchUserDetails(); 
  }

  Future<String?> _uploadToStorage(String filePath) async {
  try {
    final file = File(filePath);
    // Mengambil nama file asli tanpa tanda unik
    final originalFileName = file.uri.pathSegments.last;

    // Menyimpan dengan nama file asli di Firebase Storage
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('uploads/$originalFileName');

    final uploadTask = storageRef.putFile(file);

    // Menandakan proses upload dimulai
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    // Mendengarkan progres upload
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      setState(() {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
      });
    });

    final snapshot = await uploadTask.whenComplete(() => {});

    // Menandakan proses upload selesai
    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
    });

    return await snapshot.ref.getDownloadURL();
  } catch (e) {
    print("Error uploading to storage: $e");
    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
    });
    return null;
  }
}


  Future<void> _saveToDatabase(
  String downloadUrl, String title, String description, String hashtag, String username) async {
  final databaseRef = FirebaseDatabase.instance.ref().child('uploads');
  final newUploadRef = databaseRef.push();
  final idData = newUploadRef.key; // Mendapatkan ID unik dari Realtime Database

  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User ID not found')),
    );
    return;
  }

  try {
    await newUploadRef.set({
      'idData': idData, 
      'title': title,
      'description': description,
      'hashtag': hashtag,
      'mediaUrl': downloadUrl,
      'timestamp': DateTime.now().toIso8601String(),
      'uploadedBy': username,
      'profile': _profileImage,
      'userId': userId,
      'likes': 0,
      'isLiked': {}, // Inisialisasi sebagai Map kosong
      'type': _mediaType,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Media berhasil diupload!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

  } catch (error) {
    print('Terjadi kesalahan saat menyimpan data: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Terjadi kesalahan saat proses upload!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}





Future<String?> _getCurrentUsername() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;

  final userRef = FirebaseDatabase.instance.ref().child('users').child(userId);
  final snapshot = await userRef.get();
  if (snapshot.exists) {
    return snapshot.child('username').value as String?;
  }
  return null;
}

 Future<void> _fetchUserDetails() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userRef = FirebaseDatabase.instance.ref().child('users/${user.uid}');
    
    try {
      final snapshot = await userRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          
          _profileImage = data['profileImage'] ?? ''; // URL Foto Profil
        });
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }
}



  Future<void> _initializeMedia() async {
  final fileExtension = widget.filePath!.split('.').last.toLowerCase();
  if (fileExtension == 'mp4' || fileExtension == 'mov' || fileExtension == 'avi') {
    _mediaType = 'video'; // Set media type
    _initializeVideo();
  } else if (fileExtension == 'jpg' || fileExtension == 'jpeg' || fileExtension == 'png') {
    _mediaType = 'image'; // Set media type
    _initializeImage();
  }
}

  Future<void> _initializeVideo() async {
    final fileExists = await File(widget.filePath!).exists();
    if (fileExists) {
      _videoController = VideoPlayerController.file(File(widget.filePath!))
        ..addListener(() {
          setState(() {});
          if (_videoController!.value.position >=
              _videoController!.value.duration) {
            _videoController!.seekTo(Duration.zero);
            _videoController!.play();
          }
        })
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
        });
    }
  }

  Future<void> _initializeImage() async {
    setState(() {
      _image = Image.file(File(widget.filePath!));
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _hashtagController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    Color backgroundColor = isDarkMode ? Colors.black : Colors.grey[100]!;
    Color textColor = isDarkMode ? Colors.white : Colors.black;
    Color inputBackgroundColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    Color borderColor = isDarkMode ? Colors.grey[600]! : Colors.grey[300]!;
    Color focusedBorderColor = isDarkMode ? Colors.blue[300]! : Colors.blue;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: isDarkMode ? Colors.black : Colors.white,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Post Media',
            style: TextStyle(
                color: textColor,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        elevation: 1,
      ),
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                if (widget.filePath != null) ...[
                  if (_image != null) ...[
                    _image!,
                  ] else if (_videoController != null &&
                      _videoController!.value.isInitialized) ...[
                    AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_videoController!),
                          if (!_videoController!.value.isPlaying)
                            IconButton(
                              icon: Icon(Icons.play_circle_fill,
                                  size: 64, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _videoController!.play();
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_videoController!.value.isPlaying) {
                                _videoController!.pause();
                              } else {
                                _videoController!.play();
                              }
                            });
                          },
                        ),
                        Slider(
                          value: _videoController!.value.position.inSeconds
                              .toDouble(),
                          min: 0.0,
                          max: _videoController!.value.duration.inSeconds
                              .toDouble(),
                          onChanged: (double value) {
                            setState(() {
                              _videoController!
                                  .seekTo(Duration(seconds: value.toInt()));
                            });
                          },
                        ),
                        Text(
                          _getVideoDuration(),
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ],
                ] else
                  Center(
                    child: Text(
                      'No media selected',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                const SizedBox(height: 16),

                // Input fields
                TextField(
                  controller: _titleController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle:
                        TextStyle(color: textColor.withOpacity(0.6)),
                    hintText: 'Enter title...',
                    hintStyle:
                        TextStyle(color: textColor.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.title, color: textColor),
                    filled: true,
                    fillColor: inputBackgroundColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: focusedBorderColor),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _descriptionController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle:
                        TextStyle(color: textColor.withOpacity(0.6)),
                    hintText: 'Enter description...',
                    hintStyle:
                        TextStyle(color: textColor.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.description, color: textColor),
                    filled: true,
                    fillColor: inputBackgroundColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: focusedBorderColor),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _hashtagController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Hashtag',
                    labelStyle:
                        TextStyle(color: textColor.withOpacity(0.6)),
                    hintText: '#example',
                    hintStyle:
                        TextStyle(color: textColor.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.tag, color: textColor),
                    filled: true,
                    fillColor: inputBackgroundColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: focusedBorderColor),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          if (widget.filePath == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('No file selected')),
                            );
                            return;
                          }
                          final username = await _getCurrentUsername();
      if (username == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User data not found')),
        );
        return;
      }

                          final downloadUrl = await _uploadToStorage(widget.filePath!);
      if (downloadUrl != null) {
        final title = _titleController.text;
        final description = _descriptionController.text;
        final hashtag = _hashtagController.text;

        await _saveToDatabase(downloadUrl, title, description, hashtag, username);

                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfilePage()));

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Upload successful')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Upload failed')),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.blue),
                          backgroundColor: Colors.blue,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8)),
                        ),
                        child: Text('Upload Media'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120.0,
                          height: 120.0,
                          child : CircularProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                          strokeWidth: 6.0,
                        ),
                        ),
                        
                        Text(
                          '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Uploading...',
                      style: TextStyle( 
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getVideoDuration() {
    final duration = _videoController?.value.duration ?? Duration.zero;
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
