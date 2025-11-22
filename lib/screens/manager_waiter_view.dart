import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/models/waiter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManagerWaiterView extends StatefulWidget {
  final Waiter waiter;
  final String userId;

  const ManagerWaiterView({
    super.key,
    required this.waiter,
    required this.userId,
  });

  @override
  ManagerWaiterViewState createState() => ManagerWaiterViewState();
}

class ManagerWaiterViewState extends State<ManagerWaiterView> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String username;
  late String mobileNo;
  late String password;

  @override
  void initState() {
    super.initState();
    name = widget.waiter.name;
    username = widget.waiter.username;
    mobileNo = widget.waiter.mobileNo;
    password = widget.waiter.password;
  }

  Future<void> _saveChanges(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        Waiter updatedWaiter = Waiter(
          name: name,
          username: username,
          mobileNo: mobileNo,
          password: password,
        );

        var userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId);

        var userSnapshot = await userDocRef.get();

        if (userSnapshot.exists) {
          var userData = userSnapshot.data();
          List waitersList = userData?['waiters'] ?? [];
          var index = waitersList.indexWhere(
            (waiter) => waiter['username'] == widget.waiter.username,
          );

          if (index != -1) {
            waitersList[index] = updatedWaiter.toMap();
            await userDocRef.update({'waiters': waitersList});

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Changes saved successfully')),
            );
            Navigator.pop(context);
          }
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('User data not found')));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving changes: $e')));
      }
    }
  }

  Future<void> _removeWaiter(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'waiters': FieldValue.arrayRemove([widget.waiter.toMap()]),
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Waiter removed successfully')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing waiter: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Waiter Details',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 230, 106, 4),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          initialValue: widget.waiter.name,
                          onChanged: (value) => name = value,
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
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                          initialValue: widget.waiter.username,
                          onChanged: (value) => username = value,
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            color: const Color.fromARGB(255, 90, 57, 44),
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: GoogleFonts.lato(
                              color: const Color.fromARGB(255, 16, 15, 15),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Username is required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                          initialValue: widget.waiter.mobileNo,
                          onChanged: (value) => mobileNo = value,
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
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.lock,
                        color: Color.fromARGB(255, 90, 57, 44),
                        size: 29,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          initialValue: widget.waiter.password,
                          onChanged: (value) => password = value,
                          obscureText: false,
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
                          validator: (value) => value == null || value.isEmpty
                              ? 'Password is required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      SizedBox(width: 5),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          onPressed: () => _saveChanges(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              249,
                              111,
                              5,
                            ),
                          ),
                          child: Text(
                            'Save Changes',
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            _removeWaiter(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              249,
                              111,
                              5,
                            ),
                          ),
                          child: Text(
                            'Remove Waiter',
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
