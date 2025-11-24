import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class WaiterCheckoutScreen extends StatefulWidget {
  final String ownerUserId;
  final String table;
  final String username;

  const WaiterCheckoutScreen({
    super.key,
    required this.ownerUserId,
    required this.table,
    required this.username,
  });

  @override
  State<WaiterCheckoutScreen> createState() => _WaiterCheckoutScreenState();
}

class _WaiterCheckoutScreenState extends State<WaiterCheckoutScreen> {
  Future<void> removeItem(String itemName) async {
    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.ownerUserId);

    final snap = await ref.get();
    final data = snap.data() ?? {};

    List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(
      data["add_menu"][widget.table] ?? [],
    );

    Map<String, dynamic> totalBill = Map<String, dynamic>.from(
      data["total_bill"] ?? {},
    );

    int idx = orders.indexWhere((o) => o["name"] == itemName);

    if (idx == -1) return;

    if (orders[idx]["quantity"] > 1) {
      orders[idx]["quantity"]--;
    } else {
      orders.removeAt(idx);
    }

    double total = 0;
    for (var o in orders) {
      total += (o["price"] * o["quantity"]);
    }

    totalBill[widget.table] = total;

    await ref.update({
      "add_menu.${widget.table}": orders,
      "total_bill.${widget.table}": total,
    });

    setState(() {});
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
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(widget.ownerUserId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data() as Map<String, dynamic>;
          final addMenu = data["add_menu"] ?? {};
          final orders = List<Map<String, dynamic>>.from(
            addMenu[widget.table] ?? [],
          );

          final total = data["total_bill"][widget.table]?.toDouble() ?? 0.0;

          if (orders.isEmpty) {
            return const Center(child: Text("No items added."));
          }

          // GROUP ITEMS BY CATEGORY
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (var item in orders) {
            final category = item["category"] ?? "Other";
            grouped.putIfAbsent(category, () => []);
            grouped[category]!.add(item);
          }

          return ListView(
            padding: const EdgeInsets.all(15),
            children: [
              Text(
                "Order Summary",
                style: GoogleFonts.lato(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(thickness: 1),

              // DISPLAY GROUPED CATEGORIES
              ...grouped.entries.map((entry) {
                final category = entry.key;
                final categoryItems = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    Text(
                      category,
                      style: GoogleFonts.lato(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ...categoryItems.map((o) {
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                              "${o["name"]} x ${o["quantity"]}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                            subtitle: Text(
                              "Rs ${o["price"]}",
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                color: Colors.brown,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.brown,
                                size: 30,
                              ),
                              onPressed: () => removeItem(o["name"]),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    }).toList(),

                    const Divider(),
                  ],
                );
              }).toList(),

              const SizedBox(height: 20),

              Text(
                "Total Bill: Rs $total",
                style: GoogleFonts.lato(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }
}
