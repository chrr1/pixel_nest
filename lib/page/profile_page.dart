import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pixel_nest/auth/login.dart';
import 'package:pixel_nest/page/media_picker.dart';
import 'package:pixel_nest/page/notification_page.dart';
import 'package:pixel_nest/page/search_page.dart';
import 'package:pixel_nest/page/home_page.dart';
import 'package:flutter/services.dart';
import 'package:pixel_nest/page/upload_page.dart';


class ProfilePage extends StatefulWidget {
    final String? successMessage;

  const ProfilePage({Key? key, this.successMessage}) : super(key: key);
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
   final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("uploads");
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid; // Mendapatkan UID pengguna saat ini
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _mediaUrls = [];
  String? _username = '';
  String? _email = '';
  List<Map<String, dynamic>> _likedMediaUrls = []; // Deklarasi variabel


  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _fetchMediaUrls();
    getLikedMedia();
  }

  Future<void> _fetchUserDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _username = user.displayName ?? 'No Username'; // Nama pengguna
        _email = user.email ?? 'No Email'; // Email pengguna
      });
    }
  }

 Future<void> _fetchMediaUrls() async {
  if (_currentUserId == null) {
    print('User is not logged in');
    return;
  }

  try {
    final dataSnapshot = await _databaseRef.get();
    print('Data Snapshot: ${dataSnapshot.value}'); // Debugging untuk melihat data

    if (dataSnapshot.exists) {
      final Map<dynamic, dynamic>? data = dataSnapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _mediaUrls = data.entries
              .where((entry) => entry.value['userId'] == _currentUserId) 
              .map<String>((entry) => entry.value['mediaUrl'] as String)
              .toList();
          print('Media URLs: $_mediaUrls'); // Debugging
        });
      }
    } else {
      print('No data found');
    }
  } catch (e) {
    print('Error fetching media URLs: $e');
  }
}

void _confirmLogout() {
  bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: isDarkMode ? Colors.orange : Colors.red),
            const SizedBox(width: 8),
            Text(
              'Konfirmasi Logout',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin logout?',
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
            onPressed: () async {
              Navigator.pop(context);
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );

              // Tampilkan SnackBar setelah logout berhasil
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Berhasil logout!'),
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
              'Logout',
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


  
  int _selectedIndex = 4; // Menetapkan indeks awal untuk profil
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
    if (index == _selectedIndex) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => SearchPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
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
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              NotificationPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  void getLikedMedia() {
  final userId = FirebaseAuth.instance.currentUser?.uid; // Ambil UID user yang sedang login
  FirebaseDatabase.instance.ref('uploads').once().then((snapshot) {
    final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;
    if (data != null) {
      List<Map<String, dynamic>> mediaList = [];
      data.forEach((mediaId, mediaData) {
        // Cek apakah ada isLiked dan UID-nya sama dengan user yang login
        if (mediaData['isLiked'] != null && mediaData['isLiked'][userId] == 1) {
          mediaList.add({
            'mediaUrl': mediaData['mediaUrl'],
            'description': mediaData['description'],
            'mediaId': mediaId,
          });
        }
      });
      setState(() {
        _likedMediaUrls = mediaList;
      });
    }
  });
}




  @override
Widget build(BuildContext context) {
  bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  Color backgroundColor = isDarkMode ? Colors.black : Colors.white;
  Color textColor = isDarkMode ? Colors.white : Colors.black;

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: isDarkMode ? Colors.black : Colors.white, // Menyesuaikan warna status bar
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark, // Menyesuaikan ikon di status bar
    ),
  );
  
  return Scaffold(
    
    backgroundColor: backgroundColor,
//     appBar: AppBar(
//   automaticallyImplyLeading: false, // Menghilangkan arrow back
//   backgroundColor: Colors.transparent, // Membuat background transparan
//   elevation: 0, // Menghilangkan bayangan (shadow)
//   actions: [
//     IconButton(
//       icon: Icon(Icons.logout, color: textColor),
//       onPressed: _confirmLogout,
//     ),
//   ],
// ),

    body: SingleChildScrollView(
      
     
      child: Padding(
        
       
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             const SizedBox(height: 15),
            Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(Icons.logout, color: textColor),
              onPressed: _confirmLogout,
            ),
          ),
              const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: Text(
                _username != null && _username!.isNotEmpty ? _username![0] : 'A',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _username ?? 'Fetching username...',
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              _email ?? 'Fetching email...',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '0 pengikut',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  '0 mengikuti',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.black),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Bagikan',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    side: BorderSide(color: Colors.white),
                    backgroundColor: backgroundColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Edit Profil',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      backgroundColor: backgroundColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DefaultTabController(
  length: 3,
  child: Column(
    mainAxisSize: MainAxisSize.min, // Agar tinggi Column sesuai konten
    children: [
      // TabBar
      TabBar(
        indicatorColor: isDarkMode ? Colors.white : Colors.black,
        labelColor: isDarkMode ? Colors.white : Colors.black,
        unselectedLabelColor: Colors.grey,
        padding: EdgeInsets.zero,
        isScrollable: false,
        tabs: [
          Tab(icon: Icon(Icons.grid_on)),
          Tab(icon: Icon(Icons.favorite_border)),
          Tab(icon: Icon(Icons.bookmark_border)),
        ],
      ),
      
      // TabBarView
      Container(
        height: 600, // Tinggi konten TabBarView
        padding: EdgeInsets.zero, // Menghilangkan jarak di atas dan bawah
        margin: EdgeInsets.zero, // Menghilangkan jarak di luar container
        child: TabBarView(
          children: [
            // Konten untuk Tab Dibuat
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: _mediaUrls.isEmpty
                  ? Center(child: Text('Tidak ada media yang diunggah'))
                  : MasonryGridView.builder(
                      padding: EdgeInsets.zero, // Menghilangkan jarak di dalam grid
                      itemCount: _mediaUrls.length,
                      gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Jumlah kolom grid
                      ),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                _mediaUrls[index],
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                              progress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(child: Icon(Icons.error));
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

           Padding(
  padding: const EdgeInsets.all(4.0),
  child: _likedMediaUrls.isEmpty
      ? Center(child: Text('Tidak ada media yang disukai'))
      : MasonryGridView.builder(
          padding: EdgeInsets.zero,
          itemCount: _likedMediaUrls.length,
          gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Jumlah kolom grid
          ),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _likedMediaUrls[index]['mediaUrl'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(child: Icon(Icons.error));
                    },
                  ),
                ),
              ),
            );
          },
        ),
),



            // Konten untuk Tab Disimpan
            Center(child: Text('Konten Disimpan')),
          ],
        ),
      ),
    ],
  ),
),

          ],
        ),
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
          icon: Icon(Icons.home),
          label: 'Home',
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add),
          label: 'Add',
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notification',
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Profile',
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
        ),
      ],
    ),
  );
}

}
