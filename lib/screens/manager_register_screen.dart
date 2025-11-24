import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/screens/manager_login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final _firebase = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class ManagerRegisterScreen extends ConsumerStatefulWidget {
  const ManagerRegisterScreen({super.key});

  @override
  ConsumerState<ManagerRegisterScreen> createState() {
    return ManagerRegisterScreenState();
  }
}

class ManagerRegisterScreenState extends ConsumerState<ManagerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _password;
  var _enteredRestaurantName = '';
  var _enteredAddress = '';
  var _enteredNumber = '';
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredOwnerName = '';

  Future<void> registerSubmit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    _formKey.currentState!.save();

    try {
      final userCredentials = await _firebase.createUserWithEmailAndPassword(
        email: _enteredEmail,
        password: _enteredPassword,
      );

      await userCredentials.user!.reload();

      await userCredentials.user!
          .sendEmailVerification()
          .then((_) {
            debugPrint("Verification email sent to $_enteredEmail");
          })
          .catchError((error) {
            debugPrint("Error sending verification email: $error");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to send verification email.'),
              ),
            );
          });

      await _firestore.collection('users').doc(userCredentials.user!.uid).set({
        'Address': _enteredAddress,
        'Email': _enteredEmail,
        'Mobile No': _enteredNumber,
        'Restaurant Name': _enteredRestaurantName,
        'Owner Name': _enteredOwnerName,
        'uid': userCredentials.user!.uid,
      });

      if (!mounted) return;

      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registration successful! A verification email has been sent to $_enteredEmail.',
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (ctx) => const ManagerLoginScreen()),
      );

      _formKey.currentState!.reset();
    } catch (error) {
      if (error is FirebaseAuthException) {
        if (error.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This email is already registered.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Auth Error: ${error.message}')),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unexpected error: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ManagerLoginScreen()),
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
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        'Register',
                        style: GoogleFonts.lato(
                          fontSize: 40,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add your details to register',
                        style: GoogleFonts.poppins(
                          color: const Color.fromARGB(255, 73, 67, 67),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 15),

                      _buildInputRow(
                        icon: Icons.account_circle_outlined,
                        label: 'Restaurant Name',
                        validator: (value) => value!.isEmpty
                            ? 'Please enter the Restaurant name.'
                            : null,
                        onSaved: (value) =>
                            _enteredRestaurantName = value!.trim(),
                      ),

                      _buildInputRow(
                        icon: Icons.account_circle_outlined,
                        label: 'Owner Name',
                        validator: (value) => value!.isEmpty
                            ? 'Please enter the Owner name.'
                            : null,
                        onSaved: (value) => _enteredOwnerName = value!.trim(),
                      ),

                      _buildInputRow(
                        icon: Icons.mobile_friendly,
                        label: 'Mobile Number',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null ||
                              !RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                            return 'Please enter a valid number.';
                          }
                          return null;
                        },
                        onSaved: (value) => _enteredNumber = value!.trim(),
                      ),

                      _buildInputRow(
                        icon: Icons.email_outlined,
                        label: 'Email Address',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return 'Please enter a valid email address.';
                          }
                          return null;
                        },
                        onSaved: (value) => _enteredEmail = value!.trim(),
                      ),

                      // Address
                      _buildInputRow(
                        icon: Icons.add_home_outlined,
                        label: 'Address',
                        validator: (value) => value!.isEmpty
                            ? 'Please enter a valid address.'
                            : null,
                        onSaved: (value) => _enteredAddress = value!.trim(),
                      ),

                      _buildPasswordRow(
                        label: 'Password',
                        isVisible: _passwordVisible,
                        toggleVisibility: () {
                          setState(() => _passwordVisible = !_passwordVisible);
                        },
                        validator: (value) {
                          _password = value;
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters long.';
                          }
                          return null;
                        },
                      ),

                      _buildPasswordRow(
                        label: 'Confirm Password',
                        isVisible: _confirmPasswordVisible,
                        toggleVisibility: () {
                          setState(
                            () => _confirmPasswordVisible =
                                !_confirmPasswordVisible,
                          );
                        },
                        validator: (value) {
                          if (value == null || value != _password) {
                            return "Password doesn't match.";
                          }
                          return null;
                        },
                        onSaved: (value) => _enteredPassword = value!.trim(),
                      ),

                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: registerSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            249,
                            111,
                            5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 110,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          'Register',
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => const ManagerLoginScreen(),
                            ),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an Account? ",
                            style: GoogleFonts.poppins(
                              color: Color.fromARGB(255, 87, 83, 79),
                              fontSize: 15,
                            ),
                            children: [
                              TextSpan(
                                text: 'Login',
                                style: GoogleFonts.poppins(
                                  color: Color.fromARGB(255, 255, 123, 7),
                                  fontSize: 15,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
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

  Widget _buildInputRow({
    required IconData icon,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: const Color.fromARGB(255, 90, 57, 44), size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                label: Text(
                  label,
                  style: GoogleFonts.lato(
                    color: const Color.fromARGB(255, 140, 93, 74),
                  ),
                ),
              ),
              keyboardType: keyboardType,
              validator: validator,
              onSaved: onSaved,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRow({
    required String label,
    required bool isVisible,
    required VoidCallback toggleVisibility,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(
            Icons.password_outlined,
            color: Color.fromARGB(255, 90, 57, 44),
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                label: Text(
                  label,
                  style: GoogleFonts.lato(
                    color: const Color.fromARGB(255, 140, 93, 74),
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: toggleVisibility,
                ),
              ),
              obscureText: !isVisible,
              validator: validator,
              onSaved: onSaved,
            ),
          ),
        ],
      ),
    );
  }
}
