import 'dart:io';
import 'package:restaurant_management/screens/waiter_login_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WaiterProfileScreen extends StatefulWidget {
  final String userId;
  final String waiterIdentifier;

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
  String? mobileNo;
  String? password;
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
            .collection('users')
            .doc(widget.userId)
            .get();
        final waiters = doc.data()?['waiters'] as List<dynamic>?;

        if (waiters != null) {
          final waiterIndex = waiters.indexWhere(
            (w) => w['username'] == widget.waiterIdentifier,
          );

          if (waiterIndex != -1) {
            waiters[waiterIndex] = {
              'name': name,
              'username': username,
              'mobile no': mobileNo,
              'password': password,
            };

            await _firestore.collection('users').doc(widget.userId).update({
              'waiters': waiters,
            });

            FocusScope.of(context).unfocus();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Profile updated successfully!')),
            );
          } else {
            FocusScope.of(context).unfocus();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Waiter not found')));
          }
        }
      } catch (e) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile changes')),
        );
      }
    }
  }

  Future<void> _loadWaiterProfile() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();

        final waiters = userData?['waiters'] as List<dynamic>?;
        if (waiters != null) {
          final waiter = waiters.firstWhere(
            (w) => w['username'] == widget.waiterIdentifier,
            orElse: () => null,
          );

          if (waiter != null) {
            setState(() {
              name = waiter['name'];
              username = waiter['username'];
              mobileNo = waiter['mobile no'];
              password = waiter['password'];
              isLoading = false;
            });
          } else {
            setState(() => isLoading = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Waiter not found')));
          }
        } else {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No waiters found for this user')),
          );
        }
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User document does not exist')));
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading waiter profile')));
    }
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

  Future<void> _logout() async {
    try {
      final deviceCode = await getDeviceCode();
      final doc = await _firestore.collection('users').doc(widget.userId).get();

      if (!doc.exists) {
        throw Exception('User document not found');
      }

      final waiters = doc.data()?['waiters'] as List<dynamic>?;

      if (waiters != null) {
        final waiterIndex = waiters.indexWhere(
          (w) => w['username'] == widget.waiterIdentifier,
        );

        if (waiterIndex != -1) {
          waiters[waiterIndex]['active'] = false;
          waiters[waiterIndex]['deviceCode'] = deviceCode;
          await _firestore.collection('users').doc(widget.userId).update({
            'waiters': waiters,
          });
          await FirebaseAuth.instance.signOut();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged out successfully.')),
          );
          Navigator.of(context).pop();

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (ctx) => WaiterLoginScreen()),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Waiter not found.')));
        }
      } else {
        throw Exception('Waiters list is null');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: ${e.toString()}')),
      );
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
            'Profile',
            style: GoogleFonts.lato(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 23,
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
          'Profile',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color.fromARGB(255, 90, 57, 44),
                      size: 29,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: name,
                        style: GoogleFonts.lato(
                          color: const Color.fromARGB(255, 90, 57, 44),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: GoogleFonts.lato(
                            color: const Color.fromARGB(255, 16, 15, 15),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Name is required'
                            : null,
                        onSaved: (value) => name = value!.trim(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.account_circle,
                      size: 29,
                      color: Color.fromARGB(255, 90, 57, 44),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: username,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: const Color.fromARGB(255, 90, 57, 44),
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: GoogleFonts.lato(
                            color: const Color.fromARGB(255, 16, 15, 15),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Email is required'
                            : null,
                        onSaved: (value) => username = value!.trim(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.phone,
                      color: Color.fromARGB(255, 90, 57, 44),
                      size: 29,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: mobileNo,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: const Color.fromARGB(255, 90, 57, 44),
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Mobile No',
                          labelStyle: GoogleFonts.lato(
                            color: const Color.fromARGB(255, 16, 15, 15),
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              !RegExp(r'^[0-9]+$').hasMatch(value.trim()) ||
                              value.trim().length != 10) {
                            return 'Please enter a valid number.';
                          }
                          return null;
                        },
                        onSaved: (value) => mobileNo = value!.trim(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color.fromARGB(255, 90, 57, 44),
                      size: 29,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: password,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: const Color.fromARGB(255, 90, 57, 44),
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: GoogleFonts.lato(
                            color: const Color.fromARGB(255, 16, 15, 15),
                          ),
                        ),
                        validator: (value) {
                          password = value;
                          if (value == null || value.trim().length < 6) {
                            return 'Password must be at least 6 characters long.';
                          }
                          return null;
                        },
                        onSaved: (value) => password = value!.trim(),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        Icons.logout,
                        size: 29,
                        color: Color.fromARGB(255, 90, 57, 44),
                      ),
                      onPressed: _logout,
                      label: Text(
                        'Logout',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 90, 57, 44),
                        ),
                      ),
                    ),
                  ],
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
}
