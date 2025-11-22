import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/screens/manager_home_screen.dart';
import 'package:restaurant_management/screens/manager_login_screen.dart';
import 'package:restaurant_management/screens/waiter_home_screen.dart';
import 'package:restaurant_management/screens/waiter_login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  SelectionScreenState createState() => SelectionScreenState();
}

class SelectionScreenState extends State<SelectionScreen> {
  void manager() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) => StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(backgroundColor: Colors.white),
              );
            }

            if (snapshot.hasData) {
              return ManagerHomeScreen();
            } else {
              return ManagerLoginScreen();
            }
          },
        ),
      ),
    );
  }

  Future<String> getDeviceCode() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_device';
    }
    return 'unknown_device';
  }

  void waiter() async {
    try {
      final userDocs = await FirebaseFirestore.instance
          .collection('users')
          .get();

      String? loggedInWaiter;
      final deviceCode = await getDeviceCode();

      for (var userDoc in userDocs.docs) {
        final userData = userDoc.data() as Map<String, dynamic>?;

        if (userData != null && userData.containsKey('waiters')) {
          final waiters = userData['waiters'] as List<dynamic>;

          for (var waiter in waiters) {
            // SAFE CHECKS — prevent crash
            bool isActive = waiter['active'] ?? false;
            String savedDevice = waiter['deviceCode'] ?? "";

            if (isActive && savedDevice == deviceCode) {
              loggedInWaiter = waiter['username'];
              break;
            }
          }
        }

        if (loggedInWaiter != null) break;
      }

      if (loggedInWaiter != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => WaiterHomeScreen(username: loggedInWaiter!),
          ),
        );
      } else {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (ctx) => WaiterLoginScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  'assets/welcome_top_shape.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 240),
                    Image.asset(
                      'assets/appLogo-removebg-preview.png',
                      height: 250,
                    ),
                    Text(
                      'WELCOME',
                      style: GoogleFonts.lato(
                        color: const Color.fromARGB(255, 74, 2, 2),
                        fontSize: 55,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Every Day is an',
                      style: GoogleFonts.poppins(
                        color: const Color.fromARGB(255, 74, 2, 2),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Opportunity to Grow..!',
                      style: GoogleFonts.poppins(
                        color: const Color.fromARGB(255, 74, 2, 2),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(),
                                side: BorderSide(color: Colors.black),
                                padding: EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: manager,
                              child: Text(
                                'MANAGER',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(),
                                side: BorderSide(color: Colors.black),
                                padding: EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: waiter,
                              child: Text(
                                'WAITER',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
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
    );
  }
}
