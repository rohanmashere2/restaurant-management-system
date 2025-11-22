import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: must_be_immutable
class TableAddScreen extends ConsumerWidget {
  TableAddScreen({super.key, required this.onAdd});
  final _formKey = GlobalKey<FormState>();
  var _enteredTableName = '';
  final VoidCallback onAdd;

  void addTable(BuildContext context) async {
    _formKey.currentState!.save();
    final user = FirebaseAuth.instance.currentUser!;
    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      final userData = await userDocRef.get();
      List<dynamic> tables = userData.data()?['tables'] != null
          ? List.from(userData['tables'])
          : [];

      tables.add(_enteredTableName);
      await userDocRef.set({'tables': tables}, SetOptions(merge: true));
      Navigator.of(context).pop();

      onAdd();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Table added Successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding table: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 249, 111, 5),
        title: Text(
          'Add Table',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.table_chart,
                        color: Color.fromARGB(255, 90, 57, 44),
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Table Name',
                            labelStyle: GoogleFonts.lato(
                              fontSize: 18,
                              color: Color.fromARGB(255, 140, 93, 74),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a valid name';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredTableName = value!;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      addTable(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 249, 111, 5),
                      padding: EdgeInsets.symmetric(
                        horizontal: 100,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Add Table',
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
      ),
    );
  }
}
