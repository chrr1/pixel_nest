import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pixel_nest/page/home_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isAgreed = false;
  bool _isLoading = false;
  

 Future<void> _signUp() async {
    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to the terms and conditions')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = userCredential.user;
      if (user != null) {
        String? profileImageUrl;

        if (_profileImage != null) {
          final storageRef = FirebaseStorage.instance.ref().child("profile_images/${user.uid}.jpg");
          await storageRef.putFile(_profileImage!);
          profileImageUrl = await storageRef.getDownloadURL();
        }

        await user.updateDisplayName(
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        );
        if (profileImageUrl != null) {
          await user.updatePhotoURL(profileImageUrl);
        }

        DatabaseReference userRef = FirebaseDatabase.instance.ref("users");
        String uid = user.uid;

        await userRef.child(uid).set({
          "firstName": _firstNameController.text.trim(),
          "lastName": _lastNameController.text.trim(),
          "phone": _phoneController.text.trim(),
          "email": _emailController.text.trim(),
          "username": _usernameController.text.trim(),
          "profileImage": profileImageUrl ?? "",
          "followers": 0,
          "following": 0,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to create account')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    final colorScheme = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: colorScheme,
      appBar: AppBar(
        backgroundColor: colorScheme,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Let's create your account",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24.0),
                Align(
  alignment: Alignment.center, // Pusatkan horizontal
  child: GestureDetector(
    onTap: _pickImage,
    child: CircleAvatar(
      radius: 50,
      backgroundColor: Colors.grey[300],
      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
      child: _profileImage == null
          ? Icon(Icons.camera_alt, color: Colors.grey[800], size: 40)
          : null,
    ),
  ),
),

                const SizedBox(height: 24.0),
                TextField(
                  controller: _usernameController, // Input untuk username
                  style: TextStyle(color: textColor),
                  cursorColor: textColor,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: textColor, fontFamily: 'Poppins'),
                    prefixIcon: Icon(Icons.account_circle, color: textColor),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: textColor),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _firstNameController,
                        style: TextStyle(color: textColor),
                        cursorColor: textColor,
                        decoration: InputDecoration(
                          labelText: 'First Name',
                          labelStyle: TextStyle(color: textColor, fontFamily: 'Poppins'),
                          prefixIcon: Icon(Icons.person, color: textColor),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: textColor),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: TextField(
                        controller: _lastNameController,
                        style: TextStyle(color: textColor),
                        cursorColor: textColor,
                        decoration: InputDecoration(
                          labelText: 'Last Name',
                          labelStyle: TextStyle(color: textColor, fontFamily: 'Poppins'),
                          prefixIcon: Icon(Icons.person, color: textColor),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: textColor),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _phoneController,
                  style: TextStyle(color: textColor),
                  cursorColor: textColor,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: textColor, fontFamily: 'Poppins'),
                    prefixIcon: Icon(Icons.phone, color: textColor),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: textColor),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: textColor),
                  cursorColor: textColor,
                  decoration: InputDecoration(
                    labelText: 'E-Mail',
                    labelStyle: TextStyle(color: textColor, fontFamily: 'Poppins'),
                    prefixIcon: Icon(Icons.email, color: textColor),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: textColor),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _passwordController,
                  style: TextStyle(color: textColor),
                  cursorColor: textColor,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: textColor, fontFamily: 'Poppins'),
                    prefixIcon: Icon(Icons.lock, color: textColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: textColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: textColor),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Checkbox(
                      value: _isAgreed,
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        setState(() {
                          _isAgreed = value!;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        "I agree to Privacy Policy and Terms of use",
                        style: TextStyle(color: textColor, fontFamily: 'Poppins'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Account', style: TextStyle(fontFamily: 'Poppins')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
