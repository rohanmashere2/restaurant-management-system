import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurant_management/screens/manager_checkout_screen.dart';
import 'package:restaurant_management/widgets/main_drawer.dart';

class ManagerHomeScreen extends ConsumerStatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  ConsumerState<ManagerHomeScreen> createState() => ManagerHomeScreenState();
}

class ManagerHomeScreenState extends ConsumerState<ManagerHomeScreen> {
  bool _restaurantDialogShown = false;

  Stream<List<dynamic>> getUserTablesStream() {
    final user = FirebaseAuth.instance.currentUser!;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((docSnapshot) {
          final tables = List.from(docSnapshot.data()?['tables'] ?? []);
          return tables;
        });
  }

  Stream<String> getRestaurantNameStream() {
    final user = FirebaseAuth.instance.currentUser!;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((docSnapshot) {
          final restaurantName =
              docSnapshot.data()?['Restaurant Name'] ?? 'No Restaurant';
          return restaurantName;
        });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowRestaurantDialogIfNeeded();
    });
  }

  Future<void> _maybeShowRestaurantDialogIfNeeded() async {
    if (_restaurantDialogShown) return;

    final user = FirebaseAuth.instance.currentUser!;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final currentName = (doc.data()?['Restaurant Name'] ?? '')
        .toString()
        .trim();

    if (currentName.isNotEmpty) return;

    _restaurantDialogShown = true;

    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text("Set Restaurant Name"),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: "Restaurant Name",
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return "Required";
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set({
                      "Restaurant Name": controller.text.trim(),
                    }, SetOptions(merge: true));

                Navigator.pop(ctx);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 230, 106, 4),
        title: StreamBuilder<String>(
          stream: getRestaurantNameStream(),
          builder: (context, snapshot) {
            return Text(
              (snapshot.data ?? "Restaurant").toUpperCase(),
              style: GoogleFonts.lato(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            );
          },
        ),
      ),
      drawer: MainDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: StreamBuilder<List<dynamic>>(
          stream: getUserTablesStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final tables = snapshot.data!;

            if (tables.isEmpty) {
              return const Center(child: Text('No tables found.'));
            }

            return ListView.builder(
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final tableName = tables[index].toString();

                return TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) =>
                            ManagerCheckoutScreen(table: tableName),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.table_chart,
                        color: Color.fromARGB(255, 90, 57, 44),
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        tableName,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 90, 57, 44),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
