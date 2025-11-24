import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/screens/selection_screen.dart';
import 'package:restaurant_management/screens/waiter_home_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WaiterLoginScreen extends StatefulWidget {
  const WaiterLoginScreen({super.key});

  @override
  State<WaiterLoginScreen> createState() => WaiterLoginScreenState();
}

class WaiterLoginScreenState extends State<WaiterLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  var _enteredUserName = '';
  var _enteredPassword = '';
  bool _passwordVisible = false;

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

  Future<void> waiterLoginSubmit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    _formKey.currentState!.save();

    try {
      QuerySnapshot usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .get();

      bool loginSuccess = false;
      DocumentSnapshot? userDocument;
      int? waiterIndex;

      for (var userDoc in usersQuery.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;

        if (userData.containsKey('waiters')) {
          List<dynamic> waiters = userData['waiters'];
          for (int i = 0; i < waiters.length; i++) {
            var waiter = waiters[i];
            if (waiter['username'] == _enteredUserName &&
                waiter['password'] == _enteredPassword) {
              loginSuccess = true;
              userDocument = userDoc;
              waiterIndex = i;
              break;
            }
          }
        }
        if (loginSuccess) break;
      }

      if (loginSuccess) {
        final deviceCode = await getDeviceCode();

        List<dynamic> waiters =
            (userDocument!.data() as Map<String, dynamic>)['waiters'];

        waiters[waiterIndex!]['active'] = true;
        waiters[waiterIndex]['deviceCode'] = deviceCode;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userDocument.id)
            .set({'waiters': waiters}, SetOptions(merge: true));

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login Successful')));

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => WaiterHomeScreen(username: _enteredUserName),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SelectionScreen()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: 30),
                      Text(
                        'Login',
                        style: GoogleFonts.lato(
                          fontSize: 40,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Add your details to login',
                        style: GoogleFonts.poppins(
                          color: Color.fromARGB(255, 73, 67, 67),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: Color.fromARGB(255, 90, 57, 44),
                            size: 30,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                label: Text(
                                  'Username',
                                  style: GoogleFonts.lato(
                                    color: Color.fromARGB(255, 140, 93, 74),
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter the username.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredUserName = value!.trim();
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.password_outlined,
                            color: Color.fromARGB(255, 90, 57, 44),
                            size: 30,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                label: Text(
                                  'Password',
                                  style: GoogleFonts.lato(
                                    color: Color.fromARGB(255, 140, 93, 74),
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _passwordVisible = !_passwordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_passwordVisible,
                              validator: (value) {
                                if (value == null || value.trim().length < 6) {
                                  return 'Password must be at least 6 characters long.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredPassword = value!.trim();
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: waiterLoginSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 249, 111, 5),
                          padding: EdgeInsets.symmetric(
                            horizontal: 110,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          'Login',
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
