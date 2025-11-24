import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_management/screens/waiter_login_screen.dart';
import 'package:restaurant_management/screens/waiter_menu_screen.dart';
import 'package:restaurant_management/screens/waiter_profile_screen.dart';

class WaiterHomeScreen extends StatefulWidget {
  const WaiterHomeScreen({super.key, required this.username});

  final String username;

  @override
  State<WaiterHomeScreen> createState() => _WaiterHomeScreenState();
}

class _WaiterHomeScreenState extends State<WaiterHomeScreen> {
  late final Future<Map<String, String?>> _ownerInfoFuture;

  @override
  void initState() {
    super.initState();
    _ownerInfoFuture = _findOwnerForWaiter(widget.username);
  }

  /// Find manager-user document that contains this waiter
  Future<Map<String, String?>> _findOwnerForWaiter(String username) async {
    final snap = await FirebaseFirestore.instance.collection('users').get();

    for (final doc in snap.docs) {
      final data = doc.data();

      if (data['waiters'] == null || data['waiters'] is! List) continue;
      final List waiters = List.from(data['waiters']);

      for (final w in waiters) {
        if (w is Map && (w['username']?.toString() ?? '') == username) {
          final fullName = w['name']?.toString() ?? username;
          return {'ownerId': doc.id, 'fullName': fullName};
        }
      }
    }

    // not found
    return {'ownerId': '', 'fullName': username};
  }

  void _openMenu(String ownerId, String tableName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WaiterMenuScreen(
          username: widget.username,
          table: tableName,
          ownerUserId: ownerId, // 👈 pass manager/owner id
        ),
      ),
    );
  }

  void _openProfile(String ownerId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WaiterProfileScreen(
          userId: ownerId,
          waiterIdentifier: widget.username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => WaiterLoginScreen()),
        );
        return false;
      },
      child: FutureBuilder<Map<String, String?>>(
        future: _ownerInfoFuture,
        builder: (context, snapshot) {
          // Always white background
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || snapshot.data!['ownerId']!.isEmpty) {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: const Color.fromARGB(255, 230, 106, 4),
                title: Text(
                  widget.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              body: const Center(
                child: Text('Waiter not linked with any manager user.'),
              ),
            );
          }

          final ownerId = snapshot.data!['ownerId']!;
          final fullName = snapshot.data!['fullName']!;

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: const Color.fromARGB(255, 230, 106, 4),
              leading: IconButton(
                icon: const Icon(
                  Icons.account_circle,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => _openProfile(ownerId),
              ),
              title: Text(
                fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(10),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(ownerId)
                    .snapshots(),
                builder: (context, tableSnap) {
                  if (tableSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!tableSnap.hasData || !tableSnap.data!.exists) {
                    return const Center(child: Text('No tables found.'));
                  }

                  final data =
                      tableSnap.data!.data() as Map<String, dynamic>? ?? {};
                  final tables = List<String>.from(
                    data['tables'] as List? ?? const [],
                  );

                  if (tables.isEmpty) {
                    return const Center(child: Text('No tables found.'));
                  }

                  return ListView.builder(
                    itemCount: tables.length,
                    itemBuilder: (context, index) {
                      final tableName = tables[index];
                      return TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                        onPressed: () => _openMenu(ownerId, tableName),
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
        },
      ),
    );
  }
}
