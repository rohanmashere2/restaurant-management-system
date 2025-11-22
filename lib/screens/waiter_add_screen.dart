import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class WaiterAddScreen extends ConsumerStatefulWidget {
  const WaiterAddScreen({super.key, required this.onAdd});
  final VoidCallback onAdd;

  @override
  WaiterAddScreenState createState() => WaiterAddScreenState();
}

class WaiterAddScreenState extends ConsumerState<WaiterAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();

  bool _passwordVisible = false;

  String _enteredWName = '';
  String _enteredMobile = '';
  String _enteredUsername = '';
  String _enteredPassword = '';

  // ----------------------------------------------------------------
  // GET RESTAURANT NAME
  // ----------------------------------------------------------------
  Future<String> getRestaurantName() async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data()?['Restaurant Name'] ?? 'Your Restaurant';
  }

  // ----------------------------------------------------------------
  // SEND SMS (FREE - USER MUST TAP SEND)
  // ----------------------------------------------------------------
  Future<void> sendSMS({
    required String phone,
    required String username,
    required String password,
    required String restaurantName,
  }) async {
    final msg =
        "Congratulations! Your waiter login is created for $restaurantName.\n\n"
        "Username: $username\nPassword: $password\n\n"
        "Please keep these details safe.";

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': msg},
    );

    if (!await launchUrl(smsUri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unable to open SMS app")));
    }
  }

  // ----------------------------------------------------------------
  // ADD WAITER TO FIRESTORE
  // ----------------------------------------------------------------
  Future<void> addWaiter() async {
    final admin = FirebaseAuth.instance.currentUser!;
    final adminDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(admin.uid);

    try {
      // Check if username exists across all users
      final allUsers = await FirebaseFirestore.instance
          .collection('users')
          .get();
      bool usernameExists = false;

      for (var doc in allUsers.docs) {
        final waiters = List.from(doc.data()['waiters'] ?? []);
        if (waiters.any((w) => w['username'] == _enteredUsername.trim())) {
          usernameExists = true;
          break;
        }
      }

      if (usernameExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Username already exists")),
        );
        return;
      }

      // Fetch waiters of this admin
      final adminData = await adminDoc.get();
      List<dynamic> waiters = List.from(adminData.data()?['waiters'] ?? []);

      // New waiter entry
      final newWaiter = {
        "name": _enteredWName,
        "mobile no": _enteredMobile,
        "username": _enteredUsername,
        "password": _enteredPassword,
      };

      waiters.add(newWaiter);

      // Save back to Firestore
      await adminDoc.set({"waiters": waiters}, SetOptions(merge: true));

      // Send SMS
      final restaurantName = await getRestaurantName();
      await sendSMS(
        phone: _enteredMobile,
        username: _enteredUsername,
        password: _enteredPassword,
        restaurantName: restaurantName,
      );

      Navigator.of(context).pop();
      widget.onAdd();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Waiter added successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ----------------------------------------------------------------
  // UI
  // ----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 249, 111, 5),
        title: Text(
          'Add Waiter',
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
          padding: const EdgeInsets.all(22),

          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // NAME FIELD WITH ICON
                Row(
                  children: [
                    const Icon(
                      Icons.account_circle,
                      size: 30,
                      color: Color.fromARGB(255, 90, 57, 44),
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: "Waiter Name",
                          labelStyle: GoogleFonts.lato(
                            fontSize: 18,
                            color: Color.fromARGB(255, 140, 93, 74),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? "Enter name"
                            : null,
                        onSaved: (v) => _enteredWName = v!.trim(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // MOBILE FIELD WITH ICON
                Row(
                  children: [
                    const Icon(
                      Icons.phone_android,
                      size: 30,
                      color: Color.fromARGB(255, 90, 57, 44),
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: "Mobile Number",
                          labelStyle: GoogleFonts.lato(
                            fontSize: 18,
                            color: Color.fromARGB(255, 140, 93, 74),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value == null ||
                                !RegExp(r'^[0-9]{10}$').hasMatch(value.trim())
                            ? "Enter valid 10-digit number"
                            : null,
                        onSaved: (v) => _enteredMobile = v!.trim(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // USERNAME FIELD WITH ICON
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 30,
                      color: Color.fromARGB(255, 90, 57, 44),
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: "Username",
                          labelStyle: GoogleFonts.lato(
                            fontSize: 18,
                            color: Color.fromARGB(255, 140, 93, 74),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? "Enter username"
                            : null,
                        onSaved: (v) => _enteredUsername = v!.trim(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // PASSWORD FIELD WITH ICON
                Row(
                  children: [
                    const Icon(
                      Icons.lock,
                      size: 30,
                      color: Color.fromARGB(255, 90, 57, 44),
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: GoogleFonts.lato(
                            fontSize: 18,
                            color: Color.fromARGB(255, 140, 93, 74),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 6
                            ? "Min 6 characters"
                            : null,
                        onSaved: (v) => _enteredPassword = v!.trim(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // BUTTON
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      addWaiter();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 249, 111, 5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 90,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    "Add Waiter",
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
