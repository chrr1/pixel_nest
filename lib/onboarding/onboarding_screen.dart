import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login.dart'; // Import halaman login
import 'onboarding_page.dart'; // Import halaman OnboardingPage dari file lain

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  Future<void> _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true); // Tandai onboarding selesai
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()), // Pindah ke halaman login
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                currentPage = page;
              });
            },
            children: const [
              OnboardingPage(
                imagePath: 'assets/images/halaman_awal1.jpg',
                title: 'Easy use',
                subtitle: 'Save your memories here\nand cherish every moment.',
              ),
              OnboardingPage(
                imagePath: 'assets/images/halaman_awal2.jpg',
                title: 'Fast access',
                subtitle: 'Access your memories anywhere\nat the touch of a button.',
              ),
              OnboardingPage(
                imagePath: 'assets/images/halaman_awal3.jpg',
                title: 'Secure',
                subtitle: 'Your memories are safe with us\nwith top-notch security features.',
              ),
            ],
          ),
          // Tombol Skip
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: _completeOnboarding,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          // Indikator Halaman
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => buildDot(index, context)),
            ),
          ),
          // Tombol Next
          Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                if (currentPage == 2) {
                  _completeOnboarding(); // Tandai onboarding selesai dan arahkan ke LoginPage
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                  );
                }
              },
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 5, bottom: 10),
      height: currentPage == index ? 12 : 8,
      width: currentPage == index ? 12 : 8,
      decoration: BoxDecoration(
        color: currentPage == index ? Colors.white : Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
