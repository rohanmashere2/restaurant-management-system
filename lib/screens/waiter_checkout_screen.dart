import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class WaiterCheckoutScreen extends StatefulWidget {
  final String username;
  final String table;

  const WaiterCheckoutScreen({
    super.key,
    required this.username,
    required this.table,
  });

  @override
  State<WaiterCheckoutScreen> createState() => WaiterCheckoutScreenState();
}

class WaiterCheckoutScreenState extends State<WaiterCheckoutScreen> {
  /// Find manager userId by waiter username
  Future<String?> getUserIdByUsername(String username) async {
    try {
      final users = await FirebaseFirestore.instance.collection("users").get();

      for (var doc in users.docs) {
        final data = doc.data();

        if (data["waiters"] == null) continue;

        for (var w in List.from(data["waiters"])) {
          if (w["username"].toString().toLowerCase() ==
              username.toLowerCase()) {
            return doc.id;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Remove or decrease quantity of an item
  Future<void> removeItem(String userId, String table, String itemName) async {
    try {
      final ref = FirebaseFirestore.instance.collection("users").doc(userId);
      final snap = await ref.get();

      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final addMenu = Map<String, dynamic>.from(data["add_menu"] ?? {});
      final totalBill = Map<String, dynamic>.from(data["total_bill"] ?? {});

      List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(
        addMenu[table] ?? [],
      );

      int index = orders.indexWhere((o) => o["name"] == itemName);
      if (index == -1) return;

      final item = orders[index];

      if (item["quantity"] > 1) {
        orders[index]["quantity"]--;
        totalBill[table] -= item["price"];
      } else {
        totalBill[table] -= item["price"];
        orders.removeAt(index);
      }

      await ref.update({
        "add_menu.$table": orders,
        "total_bill.$table": totalBill[table],
      });

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error removing item")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 230, 106, 4),
        title: Text(
          "${widget.table} - Checkout",
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),

      /// GET USER ID FIRST
      body: FutureBuilder<String?>(
        future: getUserIdByUsername(widget.username),
        builder: (context, uidSnap) {
          if (uidSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userId = uidSnap.data;
          if (userId == null) {
            return const Center(child: Text("User not found."));
          }

          /// NOW STREAM TABLE ORDERS
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(userId)
                .snapshots(),
            builder: (context, orderSnap) {
              if (!orderSnap.hasData || !orderSnap.data!.exists) {
                return const Center(child: Text("No orders found."));
              }

              final userData = orderSnap.data!.data() as Map<String, dynamic>;
              final addMenu = userData["add_menu"] ?? {};
              final orders = List<Map<String, dynamic>>.from(
                addMenu[widget.table] ?? [],
              );

              final totalBill =
                  userData["total_bill"][widget.table]?.toDouble() ?? 0.0;

              /// GROUP ITEMS BY CATEGORY
              Map<String, List<Map<String, dynamic>>> grouped = {};
              for (var item in orders) {
                grouped.putIfAbsent(item["category"], () => []);
                grouped[item["category"]]!.add(item);
              }

              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Text(
                    "Order Summary",
                    style: GoogleFonts.lato(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),

                  if (orders.isEmpty)
                    Center(
                      child: Text(
                        "No items added",
                        style: GoogleFonts.lato(fontSize: 18),
                      ),
                    ),

                  /// SHOW EACH CATEGORY & ITEMS
                  ...grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ...entry.value.map((order) {
                          return ListTile(
                            title: Text(
                              "${order['name']} × ${order['quantity']}",
                              style: GoogleFonts.lato(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                            subtitle: Text(
                              "Rs ${order['price']}",
                              style: GoogleFonts.lato(color: Colors.brown),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.brown,
                                size: 30,
                              ),
                              onPressed: () {
                                removeItem(userId, widget.table, order["name"]);
                              },
                            ),
                          );
                        }),
                        const Divider(),
                      ],
                    );
                  }),

                  const SizedBox(height: 10),

                  Text(
                    "Total Bill: Rs $totalBill",
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
