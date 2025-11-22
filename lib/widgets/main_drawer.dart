import 'dart:io';
import 'package:restaurant_management/screens/bill_history_screen.dart';
import 'package:restaurant_management/screens/manager_login_screen.dart';
import 'package:restaurant_management/screens/manager_menu_screen.dart';
import 'package:restaurant_management/screens/manager_profile_screen.dart';
import 'package:restaurant_management/screens/manager_table_screen.dart';
import 'package:restaurant_management/screens/manager_waiter_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class MainDrawer extends StatelessWidget {
  MainDrawer({super.key});
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  void profile(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => ManagerProfileScreen()));
  }

  void menu(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) {
          final String? userId = FirebaseAuth.instance.currentUser?.uid;

          if (userId == null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('User is not logged in.')));
            return SizedBox();
          }
          return ManagerMenuScreen(userId: userId);
        },
      ),
    );
  }

  void table(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => ManagerTableScreen()));
  }

  void waiter(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => ManagerWaiterScreen()));
  }

  void history(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => BillHistoryScreen()));
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

  Future<void> logout(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {}
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Successfully logged out.')));

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (ctx) => ManagerLoginScreen()),
      );
    } catch (error) {
      print('Logout error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during logout.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 230, 106, 4),
                  Color.fromARGB(255, 230, 106, 4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/appLogo-removebg-preview.png',
                  height: 120,
                  width: 80,
                ),
                Text(
                  'Keep Growing!',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.account_circle,
              size: 26,
              color: Color.fromARGB(255, 90, 57, 44),
            ),
            title: Text(
              'Profile',
              style: GoogleFonts.poppins(
                color: Color.fromARGB(255, 90, 57, 44),
                fontSize: 22,
              ),
            ),
            onTap: () {
              profile(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.restaurant_menu,
              size: 26,
              color: Color.fromARGB(255, 90, 57, 44),
            ),
            title: Text(
              'Menu',
              style: GoogleFonts.poppins(
                color: Color.fromARGB(255, 90, 57, 44),
                fontSize: 22,
              ),
            ),
            onTap: () => menu(context),
          ),
          ListTile(
            leading: Icon(
              Icons.table_chart,
              size: 26,
              color: Color.fromARGB(255, 90, 57, 44),
            ),
            title: Text(
              'Tables',
              style: GoogleFonts.poppins(
                color: Color.fromARGB(255, 90, 57, 44),
                fontSize: 22,
              ),
            ),
            onTap: () => table(context),
          ),
          ListTile(
            leading: Icon(
              Icons.person,
              size: 26,
              color: Color.fromARGB(255, 90, 57, 44),
            ),
            title: Text(
              'Waiters',
              style: GoogleFonts.poppins(
                color: Color.fromARGB(255, 90, 57, 44),
                fontSize: 22,
              ),
            ),
            onTap: () => waiter(context),
          ),
          ListTile(
            leading: Icon(
              Icons.history,
              size: 26,
              color: Color.fromARGB(255, 90, 57, 44),
            ),
            title: Text(
              'History',
              style: GoogleFonts.poppins(
                color: Color.fromARGB(255, 90, 57, 44),
                fontSize: 22,
              ),
            ),
            onTap: () => history(context),
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              size: 26,
              color: Color.fromARGB(255, 90, 57, 44),
            ),
            title: Text(
              'Log Out',
              style: GoogleFonts.poppins(
                color: Color.fromARGB(255, 90, 57, 44),
                fontSize: 22,
              ),
            ),
            onTap: () => logout(context),
          ),
        ],
      ),
    );
  }
}
