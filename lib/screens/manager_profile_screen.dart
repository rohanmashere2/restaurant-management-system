import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManagerProfileScreen extends StatefulWidget {
  const ManagerProfileScreen({super.key});

  @override
  ManagerProfileScreenState createState() => ManagerProfileScreenState();
}

class ManagerProfileScreenState extends State<ManagerProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String? userId;
  String? restaurantName;
  String? email;
  String? phone;
  String? address;
  String? ownerName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser?.uid;
    if (userId != null) {
      _loadUserProfile();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      if (userId == null) return;
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          restaurantName = data?['Restaurant Name'];
          email = data?['Email'];
          phone = data?['Mobile No'];
          address = data?['Address'];
          ownerName = data?['Owner Name'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null || userId == null) return;
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('Email', isEqualTo: email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final existingUser = querySnapshot.docs.first;
          if (existingUser.id != userId) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Email is already registered with another account.',
                ),
              ),
            );
            return;
          }
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
              'Restaurant Name': restaurantName,
              'Owner Name': ownerName,
              'Email': email,
              'Mobile No': phone,
              'Address': address,
            });
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Failed to update email';
        if (e.code == 'requires-recent-login') {
          errorMessage = 'Please reauthenticate to update your email.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The provided email is invalid.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage =
              'This email is already associated with another account.';
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile changes')),
        );
      }
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
                      Icons.storefront,
                      color: Color.fromARGB(255, 90, 57, 44),
                      size: 29,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: restaurantName,
                        style: GoogleFonts.lato(
                          color: const Color.fromARGB(255, 90, 57, 44),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Restaurant Name',
                          labelStyle: GoogleFonts.lato(
                            color: const Color.fromARGB(255, 16, 15, 15),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Restaurant Name is required'
                            : null,
                        onSaved: (value) => restaurantName = value!.trim(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
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
                        initialValue: ownerName,
                        style: GoogleFonts.lato(
                          color: const Color.fromARGB(255, 90, 57, 44),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Owner Name',
                          labelStyle: GoogleFonts.lato(
                            color: const Color.fromARGB(255, 16, 15, 15),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Owner Name is required'
                            : null,
                        onSaved: (value) => ownerName = value!.trim(),
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
                        initialValue: email,
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
                        onSaved: (value) => email = value!.trim(),
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
                        initialValue: phone,
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
                        onSaved: (value) => phone = value!.trim(),
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
                        initialValue: address,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: const Color.fromARGB(255, 90, 57, 44),
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Address',
                          labelStyle: GoogleFonts.lato(
                            color: const Color.fromARGB(255, 16, 15, 15),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Address is required'
                            : null,
                        onSaved: (value) => address = value!.trim(),
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
                      fontSize: 18,
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
