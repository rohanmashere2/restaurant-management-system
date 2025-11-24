import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/screens/waiter_add_screen.dart';
import 'package:restaurant_management/screens/manager_waiter_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurant_management/models/waiter.dart';

class ManagerWaiterScreen extends ConsumerStatefulWidget {
  const ManagerWaiterScreen({super.key});

  @override
  ConsumerState<ManagerWaiterScreen> createState() =>
      ManagerWaiterScreenState();
}

class ManagerWaiterScreenState extends ConsumerState<ManagerWaiterScreen> {
  late String userDocId;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    final user = FirebaseAuth.instance.currentUser!;
    userDocId = user.uid;
  }

  Stream<List<Waiter>> getUserWaiters() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userDocId)
        .snapshots()
        .map((snapshot) {
          final waitersData = List.from(snapshot.data()?['waiters'] ?? []);
          return waitersData
              .map((waiterData) => Waiter.fromMap(waiterData))
              .toList();
        });
  }

  void addWaiter(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => WaiterAddScreen(onAdd: () {})));
  }

  void onWaiterTap(BuildContext context, Waiter waiter) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ManagerWaiterView(waiter: waiter, userId: userDocId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 230, 106, 4),
        title: Text(
          'Waiters',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            onPressed: () => addWaiter(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Waiter>>(
        stream: getUserWaiters(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No waiters found.'));
          }
          final waiters = snapshot.data!;
          return ListView.builder(
            itemCount: waiters.length,
            itemBuilder: (context, index) {
              final waiter = waiters[index];
              return ListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: Color.fromARGB(255, 90, 57, 44),
                      size: 30,
                    ),
                    SizedBox(width: 10),
                    Text(
                      waiter.name,
                      style: GoogleFonts.lato(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 90, 57, 44),
                      ),
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Color.fromARGB(255, 90, 57, 44),
                ),
                onTap: () {
                  onWaiterTap(context, waiter);
                },
              );
            },
          );
        },
      ),
    );
  }
}
