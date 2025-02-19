import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pixel_nest/page/home_page.dart';
import 'package:pixel_nest/page/media_picker.dart';

import 'package:pixel_nest/page/profile_page.dart';
import 'package:pixel_nest/page/search_page.dart';
import 'package:flutter/services.dart';
import 'package:pixel_nest/page/upload_page.dart';


class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with AutomaticKeepAliveClientMixin{

  @override
  bool get wantKeepAlive => true;

  int _selectedIndex = 3; // Menetapkan indeks awal untuk profil
  int _tabIndex = 0; // Menetapkan indeks tab awal (Pembaruan)
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
  // Menavigasi berdasarkan indeks yang dipilih di BottomNavigationBar
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
      Navigator.push(
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

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    Color backgroundColor = isDarkMode ? Colors.black : Colors.grey[100]!;
    Color textColor = isDarkMode ? Colors.white : Colors.black;
    Color secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    Color dividerColor = isDarkMode ? Colors.grey[600]! : Colors.grey;

    SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: isDarkMode ? Colors.black : Colors.white, // Menyesuaikan warna status bar
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark, // Menyesuaikan ikon di status bar
    ),
  );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.only(top: 50.0), // Margin top ditambahkan di sini
        child: Column(
          children: [
            // Bagian atas untuk "Pembaruan" dan "Kotak Masuk"
            Container(
              color: backgroundColor, // Sama dengan warna ListView
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tombol Pembaruan dengan animasi underline
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300), // Durasi animasi
                    decoration: BoxDecoration(
                      border: _tabIndex == 0
                          ? Border(
                              bottom: BorderSide(
                                color: textColor,
                                width: 2, // Lebar garis bawah
                              ),
                            )
                          : null,
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _tabIndex = 0;
                        });
                      },
                      child: Text(
                        'Pembaruan',
                        style: TextStyle(
                          color: _tabIndex == 0 ? textColor : secondaryTextColor,
                          fontFamily: 'Roboto',
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  VerticalDivider(
                    width: 20,
                    thickness: 1,
                    color: dividerColor,
                  ),
                  // Tombol Kotak Masuk dengan animasi underline
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300), // Durasi animasi
                    decoration: BoxDecoration(
                      border: _tabIndex == 1
                          ? Border(
                              bottom: BorderSide(
                                color: textColor,
                                width: 2, // Lebar garis bawah
                              ),
                            )
                          : null,
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _tabIndex = 1;
                        });
                      },
                      child: Text(
                        'Kotak Masuk',
                        style: TextStyle(
                          color: _tabIndex == 1 ? textColor : secondaryTextColor,
                          fontFamily: 'Roboto',
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bagian konten (ListView atau isi konten berdasarkan tab)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: _tabIndex == 0 // Pembaruan
                    ? ListView(
                        children: [
                          SectionTitle(title: 'Baru', textColor: textColor),
                          NotificationItem(
                            title: 'Terinspirasi oleh Anda',
                            time: '22 j',
                            avatar: Icons.person,
                            textColor: textColor,
                          ),
                          SectionTitle(title: 'Dilihat', textColor: textColor),
                          NotificationItem(
                            title: 'Masih mencari? Jelajahi ide yang terkait dengan Sport',
                            time: '1 mgg',
                            icon: Icons.search,
                            textColor: textColor,
                          ),
                        ],
                      )
                    : ListView(
                        children: [
                          SectionTitle(title: 'Pesan', textColor: textColor),
                          NotificationItem(
                            title: 'Pesan dari Tim: Perbarui profil Anda!',
                            time: '10 mgg',
                            avatar: Icons.mail,
                            textColor: textColor,
                          ),
                        ],
                      ),
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

class SectionTitle extends StatelessWidget {
  final String title;
  final Color textColor;

  const SectionTitle({required this.title, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final String title;
  final String time;
  final IconData? icon;
  final IconData? avatar;
  final Color textColor;

  const NotificationItem({
    required this.title,
    required this.time,
    this.icon,
    this.avatar,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: avatar != null
          ? CircleAvatar(
              backgroundColor: textColor.withOpacity(0.1),
              child: Icon(avatar, color: textColor),
            )
          : Icon(icon, size: 28, color: textColor),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: textColor,
        ),
      ),
      subtitle: Text(
        time,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: textColor.withOpacity(0.7),
        ),
      ),
      trailing: Icon(Icons.more_horiz, color: textColor),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: NotificationPage(),
  ));
}
