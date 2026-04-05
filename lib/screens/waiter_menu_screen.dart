import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurant_management/models/order_line_status.dart';
import 'package:restaurant_management/screens/waiter_checkout_screen.dart';

class WaiterMenuScreen extends StatefulWidget {
  const WaiterMenuScreen({
    super.key,
    required this.username,
    required this.table,
    required this.ownerUserId,
  });

  final String username;
  final String table;
  final String ownerUserId;

  @override
  State<WaiterMenuScreen> createState() => _WaiterMenuScreenState();
}

class _WaiterMenuScreenState extends State<WaiterMenuScreen> {
  String searchQuery = "";

  // store expanded state (persists across stream rebuilds)
  final Map<String, bool> expandedCategory = {};
  final Map<String, Map<String, bool>> expandedSubcategory = {};

  final _random = Random();

  String _newLineId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32)}';

  static String _lineNote(Map<String, dynamic> o) =>
      (o['note'] ?? '').toString().trim();

  /// Items with `available: false` in Firestore are treated as 86'd (sold out).
  static bool _itemAvailable(Map<String, dynamic> item) =>
      item['available'] != false;

  Future<void> _openAddSheet({
    required String category,
    required Map<String, dynamic> item,
  }) async {
    final noteController = TextEditingController();
    int quantity = 1;

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item['name']?.toString() ?? 'Item',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rs ${item['price']}',
                    style: GoogleFonts.lato(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kitchen / guest note (optional)',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 230, 106, 4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    style: GoogleFonts.lato(color: Colors.white),
                    decoration: InputDecoration(
                      hintStyle: GoogleFonts.lato(color: Colors.white),
                      hintText: 'e.g. No onion, extra spicy',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Quantity',
                        style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: quantity > 1
                            ? () => setModal(() => quantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$quantity',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setModal(() => quantity++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 230, 106, 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Add to ${widget.table}',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (added == true && mounted) {
      await addToOrder(
        category: category,
        item: item,
        quantity: quantity,
        note: noteController.text,
      );
    }
    noteController.dispose();
  }

  Future<void> addToOrder({
    required String category,
    required Map<String, dynamic> item,
    int quantity = 1,
    String note = '',
  }) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection("users")
          .doc(widget.ownerUserId);

      final snap = await docRef.get();
      final data = Map<String, dynamic>.from(snap.data() ?? {});

      Map<String, dynamic> addMenu = Map<String, dynamic>.from(
        data["add_menu"] ?? {},
      );
      Map<String, dynamic> totalBill = Map<String, dynamic>.from(
        data["total_bill"] ?? {},
      );

      List<Map<String, dynamic>> tableOrders = List<Map<String, dynamic>>.from(
        addMenu[widget.table] ?? [],
      );

      final noteTrimmed = note.trim();

      int index = tableOrders.indexWhere(
        (o) =>
            o["name"] == item["name"] &&
            o["category"] == category &&
            _lineNote(o) == noteTrimmed,
      );

      if (index >= 0) {
        final q = tableOrders[index]["quantity"];
        tableOrders[index]["quantity"] = (q as num) + quantity;
      } else {
        final line = <String, dynamic>{
          "lineId": _newLineId(),
          "name": item["name"],
          "price": item["price"],
          "quantity": quantity,
          "category": category,
          "kitchenStatus": OrderLineStatus.queued,
        };
        if (noteTrimmed.isNotEmpty) {
          line["note"] = noteTrimmed;
        }
        tableOrders.add(line);
      }

      double total = 0;
      for (var o in tableOrders) {
        total += (o["price"] as num) * (o["quantity"] as num);
      }

      addMenu[widget.table] = tableOrders;
      totalBill[widget.table] = total;

      await docRef.update({"add_menu": addMenu, "total_bill": totalBill});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            noteTrimmed.isEmpty
                ? "Added ${item['name']} × $quantity"
                : "Added ${item['name']} × $quantity (with note)",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error adding item")));
    }
  }

  void goToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WaiterCheckoutScreen(
          username: widget.username,
          table: widget.table,
          ownerUserId: widget.ownerUserId,
        ),
      ),
    );
  }

  int _cartCountFromData(Map<String, dynamic> data) {
    final addMenu = data['add_menu'] ?? {};
    final tableOrders = List<dynamic>.from(addMenu[widget.table] ?? []);
    var n = 0;
    for (final o in tableOrders) {
      if (o is Map) {
        n += (o['quantity'] as num?)?.toInt() ?? 0;
      }
    }
    return n;
  }

  double _tableSubtotalFromData(Map<String, dynamic> data) {
    final totalBill = data['total_bill'] ?? {};
    final v = totalBill[widget.table];
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 230, 106, 4),
        title: TextField(
          onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: "${widget.table} search...",
            border: InputBorder.none,
            icon: const Icon(Icons.search, color: Colors.white),
            hintStyle: GoogleFonts.lato(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.ownerUserId)
                .snapshots(),
            builder: (context, snap) {
              final docData = snap.hasData
                  ? (snap.data!.data() as Map<String, dynamic>? ?? {})
                  : <String, dynamic>{};
              final count = _cartCountFromData(docData);
              final subtotal = _tableSubtotalFromData(docData);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (subtotal > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        'Rs ${subtotal.toStringAsFixed(0)}',
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    child: IconButton(
                      icon: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                      ),
                      onPressed: goToCheckout,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.ownerUserId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Could not load menu: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
          final fullMenu = Map<String, dynamic>.from(data['menu'] ?? {});
          return buildMenuList(fullMenu);
        },
      ),
    );
  }

  Widget buildMenuList(Map<String, dynamic> fullMenu) {
    return ListView(
      children: fullMenu.keys.map((category) {
        final subcats = fullMenu[category] as Map<String, dynamic>;

        expandedCategory.putIfAbsent(category, () => false);

        // filter category — do not hide instantly
        bool categoryHasMatch = subcats.values.any((list) {
          if (list is! List) return false;
          return list.any(
            (item) =>
                item["name"].toString().toLowerCase().contains(searchQuery),
          );
        });

        if (!categoryHasMatch && searchQuery.isNotEmpty) {
          return const SizedBox.shrink();
        }

        return ExpansionTile(
          maintainState: true,
          initiallyExpanded: searchQuery.isNotEmpty
              ? true
              : expandedCategory[category]!,
          onExpansionChanged: (v) {
            if (searchQuery.isEmpty) {
              setState(() => expandedCategory[category] = v);
            }
          },
          title: Text(
            category.toUpperCase(),
            style: GoogleFonts.lato(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          children: subcats.keys.map((subcat) {
            final list = subcats[subcat];
            if (list is! List) return const SizedBox.shrink();

            final items = list
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
                .toList();

            final filtered = items.where((i) {
              final name = i["name"].toString().toLowerCase();
              return searchQuery.isEmpty || name.contains(searchQuery);
            }).toList();

            if (filtered.isEmpty) return const SizedBox.shrink();

            expandedSubcategory.putIfAbsent(category, () => {});
            expandedSubcategory[category]!.putIfAbsent(subcat, () => false);

            return ExpansionTile(
              maintainState: true,
              initiallyExpanded: searchQuery.isNotEmpty
                  ? true
                  : expandedSubcategory[category]![subcat]!,
              onExpansionChanged: (v) {
                if (searchQuery.isEmpty) {
                  setState(() {
                    expandedSubcategory[category]![subcat] = v;
                  });
                }
              },
              title: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.orange,
                child: Text(
                  subcat,
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              children: filtered.map((item) {
                final available = _itemAvailable(item);
                return ListTile(
                  enabled: available,
                  onLongPress: available
                      ? () => addToOrder(
                          category: category,
                          item: item,
                          quantity: 1,
                          note: '',
                        )
                      : null,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item["name"],
                          style: GoogleFonts.lato(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: available ? Colors.brown : Colors.grey,
                            decoration: available
                                ? TextDecoration.none
                                : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      if (!available)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '86',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    "Rs ${item["price"]}",
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      color: available ? Colors.brown : Colors.grey,
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: available
                        ? 'Tap: options · Long-press: quick add ×1'
                        : 'Unavailable',
                    icon: Icon(
                      Icons.add_shopping_cart,
                      size: 30,
                      color: available ? Colors.brown : Colors.grey,
                    ),
                    onPressed: available
                        ? () => _openAddSheet(category: category, item: item)
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Item is marked unavailable (86).',
                                ),
                              ),
                            );
                          },
                  ),
                );
              }).toList(),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
