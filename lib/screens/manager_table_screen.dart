import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/screens/table_add_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ManagerTableScreen extends ConsumerStatefulWidget {
  const ManagerTableScreen({super.key});

  @override
  ConsumerState<ManagerTableScreen> createState() => ManagerTableScreenState();
}

class ManagerTableScreenState extends ConsumerState<ManagerTableScreen> {
  // ignore: unused_field
  late Future<List<dynamic>> _userTables;

  @override
  void initState() {
    super.initState();
    _userTables = getUserTables();
  }

  Future<List<dynamic>> getUserTables() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return List.from(userDoc.data()?['tables'] ?? []);
  }

  void onAddTable() {
    setState(() {
      _userTables = getUserTables();
    });
  }

  void addTable(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => TableAddScreen(onAdd: onAddTable)),
    );
  }

  void showRemoveConfirmationDialog(BuildContext context, String tableName) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.all(20),
          content: SizedBox(
            width: 300,
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Are you sure you want to remove "$tableName"?',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 90, 57, 44),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        removeTable(context, tableName);
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 230, 106, 4),
                      ),
                      child: Text(
                        'Remove',
                        style: GoogleFonts.lato(color: Colors.white),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 230, 106, 4),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.lato(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void removeTable(BuildContext context, String tableName) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    try {
      final userData = await userDocRef.get();

      List<dynamic> tables = userData.data()?['tables'] != null
          ? List.from(userData['tables'])
          : [];

      if (tables.contains(tableName)) {
        tables.remove(tableName);

        await userDocRef.set({'tables': tables}, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Table removed successfully')),
        );

        setState(() {
          _userTables = getUserTables();
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Table not found')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing table: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 230, 106, 4),
        title: Text(
          'Tables',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () => addTable(context),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data?.data()?['tables'] == null) {
            return Center(child: Text('No tables found.'));
          }
          final tables = List.from(snapshot.data!.data()?['tables'] ?? []);
          if (tables.isEmpty) {
            return Center(child: Text('No tables found.'));
          }

          return ListView.builder(
            itemCount: tables.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.table_chart,
                      color: Color.fromARGB(255, 90, 57, 44),
                      size: 30,
                    ),
                    SizedBox(width: 10),
                    Text(
                      tables[index],
                      style: GoogleFonts.lato(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 90, 57, 44),
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  onPressed: () {
                    showRemoveConfirmationDialog(context, tables[index]);
                  },
                  icon: Icon(Icons.delete),
                  color: Colors.red,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
