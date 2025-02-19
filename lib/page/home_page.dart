import 'package:flutter/material.dart';
import 'package:pixel_nest/page/media_picker.dart';
import 'package:pixel_nest/page/upload_page.dart';
import 'package:pixel_nest/widgets/images_widget.dart';
import 'package:pixel_nest/page/profile_page.dart';
import 'package:pixel_nest/page/search_page.dart';
import 'package:pixel_nest/page/notification_page.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pixel_nest/widgets/video_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  int _selectedIndex = 0;

  void _showAddOptions(BuildContext context) async {
  final brightness = MediaQuery.of(context).platformBrightness;
  final isDarkMode = brightness == Brightness.dark;
  final ImagePicker _picker = ImagePicker();

   Future<void> _pickMediaFromGallery() async {
  // Memeriksa izin akses galeri
  if (await Permission.photos.request().isGranted) {
    // Menampilkan pilihan untuk foto atau video
    final XFile? media = await showDialog<XFile>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Media'),
          actions: <Widget>[
            TextButton(
              child: const Text('Foto'),
              onPressed: () async {
                Navigator.pop(context, await _picker.pickImage(source: ImageSource.gallery));
              },
            ),
            TextButton(
              child: const Text('Video'),
              onPressed: () async {
                Navigator.pop(context, await _picker.pickVideo(source: ImageSource.gallery));
              },
            ),
          ],
        );
      },
    );

    if (media != null) {
      // Navigasi ke UploadPage setelah media dipilih
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadPage(filePath: media.path),
        ),
      );
    } else {
      print("Tidak ada media yang dipilih.");
    }
  } else {
    print("Akses ke galeri ditolak.");
  }
}

Future<void> _captureMediaFromCamera() async {
  // Memeriksa izin akses kamera
  if (await Permission.camera.request().isGranted) {
    // Menampilkan pilihan untuk foto atau video
    final XFile? media = await showDialog<XFile>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Media'),
          actions: <Widget>[
            TextButton(
              child: const Text('Foto'),
              onPressed: () async {
                Navigator.pop(context, await _picker.pickImage(source: ImageSource.camera));
              },
            ),
            TextButton(
              child: const Text('Video'),
              onPressed: () async {
                Navigator.pop(context, await _picker.pickVideo(source: ImageSource.camera));
              },
            ),
          ],
        );
      },
    );

    if (media != null) {
      // Navigasi ke UploadPage setelah media diambil
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadPage(filePath: media.path),
        ),
      );
    } else {
      print("Tidak ada media yang diambil.");
    }
  } else {
    print("Akses ke kamera ditolak.");
  }
}





  showModalBottomSheet(
  context: context,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(20), // Border radius untuk pojok atas
    ),
  ),
  builder: (context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 180,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20), // Border radius untuk pojok atas
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tambahkan garis di bagian tengah atas
          Center(
            child: Container(
              width: 60, // Panjang garis
              height: 4,  // Ketebalan garis
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white54 : Colors.grey[400],
                borderRadius: BorderRadius.circular(2), // Membuat ujung garis melengkung
              ),
            ),
          ),
          
          
          const SizedBox(height: 30), // Jarak antara ikon X dan konten lainnya
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.camera_enhance_rounded, // Ikon modern untuk kamera
                      size: 40,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _captureMediaFromCamera();
                    },
                  ),
                  Text(
                    "Camera",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.photo_library_rounded, // Ikon modern untuk album
                      size: 40,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => MediaPickerPage()),
  );
},
                  ),
                  Text(
                    "Storage",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  },
);

}


  void _onItemTapped(int index) {
     if (index == 1) {
    Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SearchPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 2) {
     _showAddOptions(context);
    } else if (index == 3) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              MediaPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ProfilePage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  Widget _getPageContent() {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    switch (_selectedIndex) {
      case 0:
        return DefaultTabController(
          length: 6,
          child: Scaffold(
            body: SafeArea(
              child: Container(
                color: isDarkMode ? Colors.black : Colors.white,
                child: Column(
                  children: [
                    Container(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  height: 55,
  color: isDarkMode ? Colors.black : Colors.white,
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Semua",
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
          color: isDarkMode ? Colors.white : Colors.black,
          
          decorationThickness: 2,
        ),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 0), // Menghilangkan jarak antara teks dan garis
      Container(
        width: 57, // Panjang garis
        height: 4,  // Ketebalan garis
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white54 : Colors.black54,
          borderRadius: BorderRadius.circular(2), // Membuat ujung garis melengkung
        ),
      ),
    ],
  ),
),

                    Expanded(
                      child: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(
                          6,
                          (index) => const ImagesWidget(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

      case 4:
        return ProfilePage();

      default:
        return const Center(
          child: Text(
            "Unknown Page",
            style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: isDarkMode ? Colors.black : Colors.white,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: _getPageContent(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: isDarkMode ? Colors.white : Colors.black,
        unselectedItemColor: isDarkMode ? Colors.grey[600] : Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.normal,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
             
            ),
            label: 'Home',
            backgroundColor: isDarkMode ? Colors.black : Colors.white, // Background color based on theme
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.search,
             
            ),
            label: 'Search',
            backgroundColor: isDarkMode ? Colors.black : Colors.white, // Background color based on theme
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add,
             
            ),
            label: 'Add',
            backgroundColor: isDarkMode ? Colors.black : Colors.white, // Background color based on theme
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.notifications,
             
            ),
            label: 'Notification',
            backgroundColor: isDarkMode ? Colors.black : Colors.white, // Background color based on theme
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.account_circle,
             
            ),
            label: 'Profile',
            backgroundColor: isDarkMode ? Colors.black : Colors.white, // Background color based on theme
          ),
        ],
      ),
    );
  }
}
