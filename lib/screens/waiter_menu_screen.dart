import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/screens/waiter_checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WaiterMenuScreen extends StatefulWidget {
  const WaiterMenuScreen({
    super.key,
    required this.username,
    required this.table,
  });

  final String username;
  final String table;
  @override
  State<StatefulWidget> createState() {
    return WaiterMenuScreenState();
  }
}

class WaiterMenuScreenState extends State<WaiterMenuScreen> {
  String searchQuery = "";
  Map<String, bool> expandedCategory = {};
  Map<String, Map<String, bool>> expandedSubcategory = {};

  Stream<String?> getUserIdByUsernameStream(String username) {
    return FirebaseFirestore.instance.collection('users').snapshots().map((
      snapshot,
    ) {
      for (var userDoc in snapshot.docs) {
        final userData = userDoc.data();
        final waiters = userData['waiters'] as List<dynamic>;

        for (var waiter in waiters) {
          if (waiter['username'] == username) {
            return userDoc.id;
          }
        }
      }
      return null;
    });
  }

  Stream<Map<String, dynamic>> getMenuByUserIdStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            final userData = snapshot.data() as Map<String, dynamic>;
            return userData['menu'] ?? {};
          }
          return {};
        });
  }

  void addToOrder(
    String table,
    String category,
    Map<String, dynamic> item,
  ) async {
    try {
      final userId = await getUserIdByUsernameStream(widget.username).first;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User not found for username: ${widget.username}'),
          ),
        );
        return;
      }

      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      final userDocSnapshot = await userDocRef.get();
      Map<String, dynamic> currentAddMenu = {};
      Map<String, dynamic> currentTotalBill = {};

      if (userDocSnapshot.exists) {
        final rawAddMenu = userDocSnapshot.data()?['add_menu'];
        final rawTotalBill = userDocSnapshot.data()?['total_bill'];

        if (rawAddMenu != null && rawAddMenu is Map) {
          currentAddMenu = Map<String, dynamic>.from(rawAddMenu);
        }
        if (rawTotalBill != null && rawTotalBill is Map) {
          currentTotalBill = Map<String, dynamic>.from(rawTotalBill);
        }
      }
      final tableOrders = List<Map<String, dynamic>>.from(
        currentAddMenu[table] ?? [],
      );
      final itemIndex = tableOrders.indexWhere(
        (order) =>
            order['name'] == item['name'] && order['category'] == category,
      );

      if (itemIndex >= 0) {
        tableOrders[itemIndex]['quantity'] += 1;
      } else {
        tableOrders.add({
          'name': item['name'],
          'price': item['price'],
          'quantity': 1,
          'category': category,
        });
      }

      double totalBill = 0;
      for (var order in tableOrders) {
        totalBill += order['price'] * order['quantity'];
      }

      currentAddMenu[table] = tableOrders;
      currentTotalBill[table] = totalBill;

      await userDocRef.update({
        'add_menu': currentAddMenu,
        'total_bill': currentTotalBill,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Item is Added.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add item: $e')));
    }
  }

  void checkout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => WaiterCheckoutScreen(
          username: widget.username,
          table: widget.table,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: "${widget.table} search...",
            icon: Icon(Icons.search, color: Colors.white),
            hintStyle: GoogleFonts.lato(
              fontSize: 20,
              color: Color.fromARGB(232, 255, 255, 255),
            ),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
        ),
        backgroundColor: const Color.fromARGB(255, 230, 106, 4),
        actions: [
          IconButton(
            onPressed: checkout,
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            tooltip: 'Checkout',
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: StreamBuilder<String?>(
          stream: getUserIdByUsernameStream(widget.username),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('User not found.'));
            }

            final userId = snapshot.data!;
            return StreamBuilder<Map<String, dynamic>>(
              stream: getMenuByUserIdStream(userId),
              builder: (context, menuSnapshot) {
                if (menuSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!menuSnapshot.hasData || menuSnapshot.data!.isEmpty) {
                  return const Center(child: Text('No menu found.'));
                }

                final menu = menuSnapshot.data!;
                return ListView(
                  children: menu.keys.map((category) {
                    final subcategories =
                        menu[category] as Map<String, dynamic>;
                    // Track whether the category is expanded or not
                    expandedCategory[category] =
                        expandedCategory[category] ?? false;

                    return ExpansionTile(
                      title: Text(
                        category.toUpperCase(),
                        style: GoogleFonts.lato(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 90, 57, 44),
                        ),
                      ),
                      onExpansionChanged: (expanded) {
                        setState(() {
                          expandedCategory[category] = expanded;
                        });
                      },
                      initiallyExpanded: expandedCategory[category]!,
                      children: subcategories.keys.map((subcat) {
                        final items = List<Map<String, dynamic>>.from(
                          subcategories[subcat],
                        );
                        items.sort(
                          (a, b) => (a['name'] as String).compareTo(
                            b['name'] as String,
                          ),
                        );

                        final filteredItems = items.where((item) {
                          final itemName = (item['name'] as String)
                              .toLowerCase();
                          return itemName.contains(searchQuery);
                        }).toList();

                        if (filteredItems.isEmpty) {
                          return Container();
                        }
                        expandedSubcategory[category] ??= {};
                        expandedSubcategory[category]![subcat] =
                            expandedSubcategory[category]![subcat] ?? false;

                        return ExpansionTile(
                          title: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                            ),
                            child: Text(
                              subcat,
                              style: GoogleFonts.lato(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          onExpansionChanged: (expanded) {
                            setState(() {
                              expandedSubcategory[category]![subcat] = expanded;
                            });
                          },
                          initiallyExpanded:
                              expandedSubcategory[category]![subcat]!,
                          children: filteredItems.map((item) {
                            return Container(
                              color: Colors.white,
                              child: ListTile(
                                title: Text(
                                  item['name'],
                                  style: GoogleFonts.lato(
                                    fontSize: 19,
                                    color: const Color.fromARGB(
                                      255,
                                      90,
                                      57,
                                      44,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Rs ${item['price']}',
                                      style: GoogleFonts.lato(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        color: const Color.fromARGB(
                                          255,
                                          90,
                                          57,
                                          44,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.add,
                                    size: 35,
                                    color: Color.fromARGB(255, 90, 57, 44),
                                  ),
                                  onPressed: () =>
                                      addToOrder(widget.table, category, item),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
