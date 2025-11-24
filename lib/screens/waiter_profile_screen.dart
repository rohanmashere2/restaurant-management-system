import 'dart:io';
import 'package:restaurant_management/screens/waiter_login_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WaiterProfileScreen extends StatefulWidget {
  final String userId;
  final String waiterIdentifier; // original username passed from login

  const WaiterProfileScreen({
    super.key,
    required this.userId,
    required this.waiterIdentifier,
  });

  @override
  WaiterProfileScreenState createState() => WaiterProfileScreenState();
}

class WaiterProfileScreenState extends State<WaiterProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? name;
  String? username;
  String? restaurantName; // 👈 NEW
  String? mobileNo;
  String? password;

  /// Stores the ORIGINAL username of the waiter in Firestore
  String? oldUsername;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWaiterProfile();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final doc = await _firestore
            .collection("users")
            .doc(widget.userId)
            .get();
        final waiters = doc.data()?['waiters'] as List<dynamic>?;

        if (waiters != null) {
          final waiterIndex = waiters.indexWhere(
            (w) => w['username'] == oldUsername, // USE ORIGINAL USERNAME
          );

          if (waiterIndex != -1) {
            waiters[waiterIndex] = {
              "name": name,
              "username": username,
              "restaurantName": restaurantName, // 👈 SAVE RESTAURANT
              "mobile no": mobileNo,
              "password": password,
              "active": waiters[waiterIndex]["active"] ?? true,
              "deviceCode": waiters[waiterIndex]["deviceCode"] ?? "",
            };

            await _firestore.collection('users').doc(widget.userId).update({
              'waiters': waiters,
            });

            oldUsername = username; // UPDATE old username for next edit

            FocusScope.of(context).unfocus();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile updated successfully!")),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Waiter not found")));
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
      }
    }
  }

  Future<void> _loadWaiterProfile() async {
    try {
      final doc = await _firestore.collection("users").doc(widget.userId).get();

      if (doc.exists) {
        final data = doc.data();
        final waiters = data?['waiters'] as List<dynamic>?;

        if (waiters != null) {
          final waiter = waiters.firstWhere(
            (w) => w['username'] == widget.waiterIdentifier,
            orElse: () => null,
          );

          if (waiter != null) {
            setState(() {
              name = waiter['name'];
              username = waiter['username'];
              restaurantName =
                  waiter['restaurantName'] ??
                  data?['Restaurant Name']; // 👈 fallback to owner field
              mobileNo = waiter['mobile no'];
              password = waiter['password'];

              oldUsername = waiter['username']; // STORE ORIGINAL USERNAME
              isLoading = false;
            });
          } else {
            setState(() => isLoading = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Waiter not found")));
          }
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading profile: $e")));
    }
  }

  Future<String> getDeviceCode() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      return android.id;
    } else if (Platform.isIOS) {
      final ios = await info.iosInfo;
      return ios.identifierForVendor ?? "unknown_device";
    }
    return "unknown_device";
  }

  Future<void> _logout() async {
    try {
      final deviceCode = await getDeviceCode();
      final doc = await _firestore.collection("users").doc(widget.userId).get();

      final waiters = doc.data()?['waiters'] as List<dynamic>?;

      if (waiters != null) {
        final index = waiters.indexWhere((w) => w['username'] == oldUsername);

        if (index != -1) {
          waiters[index]['active'] = false;
          waiters[index]['deviceCode'] = deviceCode;

          await _firestore.collection("users").doc(widget.userId).update({
            "waiters": waiters,
          });

          await FirebaseAuth.instance.signOut();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Logged out successfully")),
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => WaiterLoginScreen()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Logout failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 230, 106, 4),
          title: Text(
            "Profile",
            style: GoogleFonts.lato(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 230, 106, 4),
        title: Text(
          "Profile",
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Name
                _buildField(
                  label: "Name",
                  icon: Icons.person,
                  initial: name,
                  onSaved: (v) => name = v!,
                ),

                // Username
                _buildField(
                  label: "Username",
                  icon: Icons.account_circle,
                  initial: username,
                  onSaved: (v) => username = v!,
                ),

                // 👇 NEW: Restaurant Name (after username)
                _buildField(
                  label: "Restaurant Name",
                  icon: Icons.storefront,
                  initial: restaurantName,
                  onSaved: (v) => restaurantName = v!,
                ),

                // Mobile
                _buildField(
                  label: "Mobile No",
                  icon: Icons.phone,
                  initial: mobileNo,
                  validator: (v) => v == null || v.trim().length != 10
                      ? "Enter valid mobile number"
                      : null,
                  onSaved: (v) => mobileNo = v!,
                ),

                // Password
                _buildField(
                  label: "Password",
                  icon: Icons.lock,
                  initial: password,
                  validator: (v) => v == null || v.trim().length < 6
                      ? "Min 6 characters"
                      : null,
                  onSaved: (v) => password = v!,
                ),

                const SizedBox(height: 15),
                TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.brown, size: 20),
                  label: Text(
                    "Logout",
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    backgroundColor: const Color.fromARGB(255, 230, 106, 4),
                  ),
                  onPressed: _saveProfile,
                  child: Text(
                    'Save Profile',
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required String? initial,
    required FormFieldSetter<String> onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 28, color: const Color.fromARGB(255, 90, 57, 44)),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              initialValue: initial,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.lato(
                  color: const Color.fromARGB(255, 16, 15, 15),
                ),
              ),
              style: GoogleFonts.lato(
                fontSize: 18,
                color: const Color.fromARGB(255, 90, 57, 44),
                fontWeight: FontWeight.bold,
              ),
              validator:
                  validator ??
                  (v) => (v == null || v.isEmpty) ? "Required" : null,
              onSaved: onSaved,
            ),
          ),
        ],
      ),
    );
  }
}
