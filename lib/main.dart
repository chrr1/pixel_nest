import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:pixel_nest/auth/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'onboarding/onboarding_screen.dart'; // Import halaman onboarding
import 'firebase_options.dart';

import 'package:permission_handler/permission_handler.dart';

Future<void> requestStoragePermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
  }

  if (!status.isGranted) {
    print("Izin penyimpanan tidak diberikan!");
  } else {
    print("Izin penyimpanan diberikan!");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Terjadi kesalahan saat inisialisasi Firebase: $e");
  }

  await requestStoragePermission(); // Minta izin penyimpanan di awal

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkOnboardingStatus() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('onboarding_complete') ?? false; // Default false
    } catch (e) {
      print("Terjadi kesalahan saat mengambil data SharedPreferences: \$e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkOnboardingStatus(),
      builder: (context, snapshot) {
        // Menampilkan loading hingga pengecekan selesai
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Terjadi kesalahan'),
              ),
            ),
          );
        } else {
          // Jika sudah selesai onboarding, arahkan ke LoginScreen
          final bool hasCompletedOnboarding = snapshot.data ?? false;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: hasCompletedOnboarding
                ? const LoginPage()
                : const OnboardingScreen(),
          );
        }
      },
    );
  }
}
