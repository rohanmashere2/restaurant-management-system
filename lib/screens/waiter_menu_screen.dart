import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  Map<String, dynamic> fullMenu = {}; // store menu locally
  bool isLoading = true;

  // store expanded state
  final Map<String, bool> expandedCategory = {};
  final Map<String, Map<String, bool>> expandedSubcategory = {};

  @override
  void initState() {
    super.initState();
    loadMenu();
  }

  Future<void> loadMenu() async {
    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.ownerUserId)
        .get();

    final data = snap.data() as Map<String, dynamic>? ?? {};
    fullMenu = Map<String, dynamic>.from(data["menu"] ?? {});

    setState(() => isLoading = false);
  }

  Future<void> addToOrder({
    required String category,
    required Map<String, dynamic> item,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection("users")
          .doc(widget.ownerUserId);

      final snap = await docRef.get();
      final data = snap.data() as Map<String, dynamic>? ?? {};

      Map<String, dynamic> addMenu = Map<String, dynamic>.from(
        data["add_menu"] ?? {},
      );
      Map<String, dynamic> totalBill = Map<String, dynamic>.from(
        data["total_bill"] ?? {},
      );

      List<Map<String, dynamic>> tableOrders = List<Map<String, dynamic>>.from(
        addMenu[widget.table] ?? [],
      );

      int index = tableOrders.indexWhere(
        (o) => o["name"] == item["name"] && o["category"] == category,
      );

      if (index >= 0) {
        tableOrders[index]["quantity"]++;
      } else {
        tableOrders.add({
          "name": item["name"],
          "price": item["price"],
          "quantity": 1,
          "category": category,
        });
      }

      double total = 0;
      for (var o in tableOrders) {
        total += (o["price"] as num) * (o["quantity"] as num);
      }

      addMenu[widget.table] = tableOrders;
      totalBill[widget.table] = total;

      await docRef.update({"add_menu": addMenu, "total_bill": totalBill});

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Item Added")));
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
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: goToCheckout,
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : buildMenuList(),
    );
  }

  Widget buildMenuList() {
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
                return ListTile(
                  title: Text(
                    item["name"],
                    style: GoogleFonts.lato(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  subtitle: Text(
                    "Rs ${item["price"]}",
                    style: GoogleFonts.lato(fontSize: 15, color: Colors.brown),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add, size: 32, color: Colors.brown),
                    onPressed: () => addToOrder(category: category, item: item),
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
