import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pixel_nest/models/media_data.dart';
import 'package:pixel_nest/page/media_picker.dart';
import 'package:pixel_nest/page/notification_page.dart';
import 'package:pixel_nest/page/upload_page.dart';
import 'dart:async';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:pixel_nest/page/profile_page.dart'; // Pastikan halaman ada
import 'package:pixel_nest/page/home_page.dart'; // Jika ada
import 'package:flutter/services.dart';
import 'package:pixel_nest/page/image_detail_page.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with AutomaticKeepAliveClientMixin{
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("uploads");
  List<MediaData> _filteredMedia = [];
   List<MediaData> _filteredMedia2 = [];
   List<MediaData> _filteredMedia3 = [];
    List<MediaData> _allMedia = [];
  List<MediaData> _searchResults = [];
   List<MediaData> mediaPaths = [];
  TextEditingController _searchController = TextEditingController();
  @override
  bool get wantKeepAlive => true;

  int _selectedIndex = 1;

  void _showAddOptions(BuildContext context) async {
  final brightness = MediaQuery.of(context).platformBrightness;
  final isDarkMode = brightness == Brightness.dark;
  final ImagePicker _picker = ImagePicker();

  Future<void> _accessCamera() async {
  if (await Permission.camera.request().isGranted) {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      print('Foto diambil dari kamera: ${photo.path}');
      // Navigasi ke UploadPage dengan path gambar yang diambil
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadPage(filePath: photo.path),
        ),
      );
    } else {
      print('Tidak ada foto yang dipilih.');
    }
  } else {
    print('Izin kamera ditolak.');
  }
}

Future<void> _accessStorage() async {
  if (await Permission.photos.request().isGranted) {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      print('Foto diambil dari galeri: ${image.path}');
      // Navigasi ke UploadPage dengan path gambar yang diambil
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadPage(filePath: image.path),
        ),
      );
    } else {
      print('Tidak ada foto yang dipilih.');
    }
  } else {
    print('Izin penyimpanan ditolak.');
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
                      await _accessCamera();
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
                    onPressed: () async {
                      Navigator.pop(context);
                      await _accessStorage();
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
    setState(() {
      _selectedIndex = index; // Memperbarui status indeks
    });

    // Navigasi berdasarkan indeks
    if (index == 0) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 1) {
      // Uncomment dan tambahkan halaman jika diperlukan
    } else if (index == 2) {
       Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MediaPickerPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => NotificationPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ProfilePage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  final List<String> _bannerImages = [
    'assets/category/banner1.jpg',
    'assets/category/banner2.jpg',
    'assets/category/banner3.jpg',
  ];

  

  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late Timer _sliderTimer; // Timer untuk auto-slide

  @override
  void initState() {
    super.initState();
    _fetchFilteredMedia();
    _fetchFilteredMedia2();
    _fetchFilteredMedia3();
    _fetchAllMedia();
    
    // Timer untuk auto-slide
    _sliderTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_currentIndex < _bannerImages.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _pageController.animateToPage(
        _currentIndex,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {});
    });
  }

  Future<void> _fetchAllMedia() async {
    try {
      final snapshot = await _databaseRef.get();
      if (snapshot.exists) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
        final User? user = FirebaseAuth.instance.currentUser;
        final String currentUserId = user?.uid ?? '';

        final mediaList = data.entries
            .map((entry) => MediaData.fromMap(Map<String, dynamic>.from(entry.value), currentUserId))
            .toList();

        setState(() {
          _allMedia = mediaList;
          _searchResults = mediaList;
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        _allMedia = [];
        _searchResults = [];
      });
    }
  }

  void _searchMedia(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = _allMedia;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    final results = _allMedia.where((media) =>
        media.title.toLowerCase().contains(lowerQuery) ||
        media.description.toLowerCase().contains(lowerQuery) ||
        media.hashtag.toLowerCase().contains(lowerQuery)
    ).toList();

    setState(() {
      _searchResults = results;
    });
  }

  Future<void> _fetchFilteredMedia() async {
  try {
    final snapshot = await _databaseRef.get();
    if (snapshot.exists) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
      print("Data from Firebase: $data");

      // Ambil user yang sedang login
      final User? user = FirebaseAuth.instance.currentUser;
      final String currentUserId = user?.uid ?? '';

      final filtered = data.entries
          .map((entry) => MediaData.fromMap(Map<String, dynamic>.from(entry.value), currentUserId))
          .where((media) => media.hashtag == '#fyp')
          .toList();

      print("Filtered Media: $filtered");

      setState(() {
        _filteredMedia = filtered;
      });
    } else {
      print("No data found.");
      setState(() {
        _filteredMedia = [];
      });
    }
  } catch (e) {
    print("Error fetching data: $e");
    setState(() {
      _filteredMedia = [];
    });
  }
}



Future<void> _fetchFilteredMedia2() async {
  try {
    final snapshot = await _databaseRef.get();
    if (snapshot.exists) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
      print("Data from Firebase: $data");

      // Ambil user yang sedang login
      final User? user = FirebaseAuth.instance.currentUser;
      final String currentUserId = user?.uid ?? '';

      final filtered = data.entries
          .map((entry) => MediaData.fromMap(Map<String, dynamic>.from(entry.value), currentUserId))
          .where((media) => media.hashtag == '#foryourpixel')
          .toList();

      print("Filtered Media: $filtered");

      setState(() {
        _filteredMedia2 = filtered;
      });
    } else {
      print("No data found.");
      setState(() {
        _filteredMedia2 = [];
      });
    }
  } catch (e) {
    print("Error fetching data: $e");
    setState(() {
      _filteredMedia2 = [];
    });
  }
}


Future<void> _fetchFilteredMedia3() async {
  try {
    final snapshot = await _databaseRef.get();
    if (snapshot.exists) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
      print("Data from Firebase: $data");

      // Ambil user yang sedang login
      final User? user = FirebaseAuth.instance.currentUser;
      final String currentUserId = user?.uid ?? '';

      final filtered = data.entries
          .map((entry) => MediaData.fromMap(Map<String, dynamic>.from(entry.value), currentUserId))
          .where((media) => media.hashtag == '#aesthetic')
          .toList();

      print("Filtered Media: $filtered");

      setState(() {
        _filteredMedia3 = filtered;
      });
    } else {
      print("No data found.");
      setState(() {
        _filteredMedia3 = [];
      });
    }
  } catch (e) {
    print("Error fetching data: $e");
    setState(() {
        _filteredMedia3 = [];
    });
  }
}





  @override
  void dispose() {
    // Batalkan timer saat widget dihancurkan
    _sliderTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildCategoryImage(MediaData mediaData) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageDetailPage(mediaData: mediaData), // Mengirimkan objek MediaData ke halaman detail
        ),
      );
    },
    child: Container(
      width: 100.0,
      height: 130.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3.0),
        image: DecorationImage(
          image: NetworkImage(mediaData.mediaUrl),  // Menggunakan URL gambar dari MediaData
          fit: BoxFit.cover,
        ),
      ),
    ),
  );
}




  @override
  
Widget build(BuildContext context) {
  // Mengecek mode terang atau gelap
  bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: isDarkMode ? Colors.black : Colors.white, // Menyesuaikan warna status bar
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark, // Menyesuaikan ikon di status bar
    ),
  );
  
  return Scaffold(
    backgroundColor: isDarkMode ? Colors.black : Colors.white, // Mengubah latar belakang sesuai mode
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Cari media...",
          border: OutlineInputBorder(),
        ),
        onChanged: _searchMedia,
      ),
            ),
          
          Expanded(
            
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final media = _searchResults[index];
                return ListTile(
                  leading: Image.network(media.mediaUrl, width: 50, height: 50, fit: BoxFit.cover),
                  title: Text(media.title),
                  subtitle: Text(media.description),
                  
                );
              },
              
            ),
          ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    body: SingleChildScrollView(
      // Memastikan tampilan scrollable
      child: Column(
        children: [
          // Image Slider using PageView for Banners
          Container(
            height: 200.0,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _bannerImages.length,
              itemBuilder: (context, index) {
                return Image.asset(
                  _bannerImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                );
              },
            ),
          ),
          SizedBox(height: 16.0), // Jarak antara slider dan indikator
          // Indikator Bundar
          SmoothPageIndicator(
            controller: _pageController,
            count: _bannerImages.length,
            effect: WormEffect(
              dotWidth: 8.0,
              dotHeight: 8.0,
              spacing: 16.0,
              dotColor: isDarkMode ? Colors.grey : Colors.grey,
              activeDotColor: Colors.blue,
            ),
          ),
         
        ],
      ),
    ),
   bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white, // BottomNav background color based on theme
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: isDarkMode ? Colors.white : Colors.black, // Selected item color
        unselectedItemColor: isDarkMode ? Colors.grey[600] : Colors.grey, // Unselected item color
        selectedLabelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
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

