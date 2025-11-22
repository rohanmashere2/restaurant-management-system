import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/screens/waiter_menu_screen.dart';
import 'package:restaurant_management/screens/waiter_profile_screen.dart';
import 'package:flutter/material.dart';

class WaiterHomeScreen extends StatefulWidget {
  const WaiterHomeScreen({super.key, required this.username});

  final String username;

  @override
  State<WaiterHomeScreen> createState() => WaiterHomeScreenState();
}

class WaiterHomeScreenState extends State<WaiterHomeScreen> {
  Stream<Map<String, String?>> getWaiterDetailsStream(String username) {
    return FirebaseFirestore.instance.collection('users').snapshots().map((
      snapshot,
    ) {
      for (var userDoc in snapshot.docs) {
        final data = userDoc.data();

        // SAFE CHECK — if waiters is missing or null, skip this doc
        if (data['waiters'] == null ||
            data['waiters'] is! List ||
            (data['waiters'] as List).isEmpty) {
          continue;
        }

        final waiters = List.from(data['waiters']);

        for (var waiter in waiters) {
          if (waiter['username'] == username) {
            return {
              'userId': userDoc.id,
              'fullName': waiter['name'] ?? username,
            };
          }
        }
      }

      // If no waiter found
      return {'userId': null, 'fullName': null};
    });
  }

  Stream<List<String>> getTablesStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((docSnapshot) {
          if (docSnapshot.exists) {
            final userData = docSnapshot.data() as Map<String, dynamic>;
            return List<String>.from(userData['tables'] ?? []);
          }
          return [];
        });
  }

  void waiterMenu(String username, String table) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => WaiterMenuScreen(username: username, table: table),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: StreamBuilder<Map<String, String?>>(
          stream: getWaiterDetailsStream(widget.username),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!['userId'] == null) {
              return const Icon(Icons.error, color: Colors.white, size: 30);
            }

            final userId = snapshot.data!['userId']!;
            return IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => WaiterProfileScreen(
                      userId: userId,
                      waiterIdentifier: widget.username,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.account_circle,
                color: Colors.white,
                size: 30,
              ),
            );
          },
        ),
        backgroundColor: const Color.fromARGB(255, 230, 106, 4),
        title: StreamBuilder<Map<String, String?>>(
          stream: getWaiterDetailsStream(widget.username),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(color: Colors.white);
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!['fullName'] == null) {
              return Text(
                widget.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }

            final fullName = snapshot.data!['fullName']!;
            return Text(
              fullName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: StreamBuilder<Map<String, String?>>(
          stream: getWaiterDetailsStream(widget.username),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!['userId'] == null) {
              return const Center(child: Text('User not found.'));
            }

            final userId = snapshot.data!['userId']!;
            return StreamBuilder<List<String>>(
              stream: getTablesStream(userId),
              builder: (context, tableSnapshot) {
                if (tableSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (tableSnapshot.hasError ||
                    !tableSnapshot.hasData ||
                    tableSnapshot.data!.isEmpty) {
                  return const Center(child: Text('No tables found.'));
                }

                final tables = tableSnapshot.data!;
                return ListView.builder(
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                    return TextButton(
                      onPressed: () {
                        waiterMenu(widget.username, tables[index]);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.table_chart,
                            color: Color.fromARGB(255, 90, 57, 44),
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            tables[index],
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 90, 57, 44),
                            ),
                          ),
                          const SizedBox(height: 35),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
