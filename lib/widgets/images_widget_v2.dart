
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ImagesWidget extends StatelessWidget {
  const ImagesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Daftar gambar yang akan ditampilkan secara manual
    List<String> imagePaths = [
      'assets/images/1.jpg',
      'assets/images/2.jpg',
      'assets/images/3.jpg',
      'assets/images/4.jpg',
      'assets/images/5.jpg',
      'assets/images/6.jpg',
      'assets/images/7.jpg',
      'assets/images/8.jpg',
      'assets/images/9.jpg',
      'assets/images/10.jpeg',
      'assets/images/11.jpg',
      'assets/images/12.jpg',
      'assets/images/13.jpg',
      'assets/images/14.jpg',
      'assets/images/15.jpg',
      'assets/images/16.jpg',
    ];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MasonryGridView.builder(
        itemCount: imagePaths.length,
        gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemBuilder: (BuildContext context, int index) {
          // Menghasilkan aspect ratio acak antara 0.8 dan 1.5 untuk variasi ukuran gambar
          double aspectRatio = (index % 2 == 0) ? 0.8 : 1.5;

          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              children: [
                // Menjaga gambar agar tidak terpotong dengan BoxFit.cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Image.asset(
                      imagePaths[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                SizedBox(height: 8), // Memberi jarak antara gambar dan bar aksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Profil di kiri
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),

                    // Titik tiga di kanan
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          // Tambahkan aksi untuk tiga titik di sini
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}