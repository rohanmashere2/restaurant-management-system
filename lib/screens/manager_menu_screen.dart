import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/screens/menu_add_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManagerMenuScreen extends StatefulWidget {
  const ManagerMenuScreen({super.key, required this.userId});
  final String userId;

  @override
  State<StatefulWidget> createState() {
    return ManagerMenuScreenState();
  }
}

class ManagerMenuScreenState extends State<ManagerMenuScreen> {
  late Stream<DocumentSnapshot> _menuStream;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _menuStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots();
  }

  void addMenu(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => MenuAddScreen()));
  }

  void removeMenuItem(
    String category,
    String subcategory,
    String itemName,
    String itemPrice,
  ) async {
    try {
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId);
      final userDocSnapshot = await userDocRef.get();
      final menu = userDocSnapshot.data()?['menu'] ?? {};

      if (menu.isNotEmpty) {
        final updatedMenu = Map<String, dynamic>.from(menu);

        if (updatedMenu.containsKey(category)) {
          var subcategories = updatedMenu[category];

          if (subcategories.containsKey(subcategory)) {
            List<dynamic> items = List.from(subcategories[subcategory]);

            double priceToRemove =
                double.tryParse(itemPrice.replaceAll('Rs ', '')) ?? 0.0;

            items.removeWhere(
              (item) =>
                  item['name'] == itemName && item['price'] == priceToRemove,
            );

            subcategories[subcategory] = items;
          }
        }

        await userDocRef.update({'menu': updatedMenu});
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: 'Search Items...',
            hintStyle: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            border: InputBorder.none,
            icon: const Icon(Icons.search, color: Colors.white),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            onPressed: () => addMenu(context),
          ),
        ],
        backgroundColor: const Color.fromARGB(255, 230, 106, 4),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: StreamBuilder<DocumentSnapshot>(
          stream: _menuStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                !snapshot.data!.exists) {
              return const Center(child: Text('No menu found.'));
            }
            final menu = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            if (menu.isEmpty || menu['menu'] == null) {
              return const Center(child: Text('No menu found.'));
            }
            final menuData = menu['menu'] as Map<String, dynamic>;

            return ListView(
              children: menuData.keys
                  .where((category) {
                    return _searchQuery.isEmpty ||
                        category.toLowerCase().contains(_searchQuery) ||
                        menuData[category].values.any((subcategory) {
                          if (subcategory is List) {
                            return subcategory.any((item) {
                              return item['name'].toLowerCase().contains(
                                    _searchQuery,
                                  ) ||
                                  item['price'].toString().contains(
                                    _searchQuery,
                                  );
                            });
                          }
                          return false;
                        });
                  })
                  .map((category) {
                    final subcategories =
                        menuData[category] as Map<String, dynamic>;
                    return ExpansionTile(
                      title: Text(
                        category.toUpperCase(),
                        style: GoogleFonts.lato(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 90, 57, 44),
                        ),
                      ),
                      children: subcategories.keys.map((subcat) {
                        final items = List<Map<String, dynamic>>.from(
                          subcategories[subcat],
                        );
                        items.sort(
                          (a, b) => (a['name'] as String).compareTo(
                            b['name'] as String,
                          ),
                        );

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
                          children: items
                              .where((item) {
                                final itemName = item['name'] ?? 'Unknown';
                                final itemPrice = item['price'] != null
                                    ? 'Rs ${item['price']}'
                                    : '';
                                return _searchQuery.isEmpty ||
                                    itemName.toLowerCase().contains(
                                      _searchQuery,
                                    ) ||
                                    itemPrice.toLowerCase().contains(
                                      _searchQuery,
                                    );
                              })
                              .map((item) {
                                final itemName = item['name'] ?? 'Unknown';
                                final itemPrice = item['price'] != null
                                    ? 'Rs ${item['price']}'
                                    : 'Price not available';

                                return Container(
                                  color: Colors.white,
                                  child: ListTile(
                                    title: Text(
                                      itemName,
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
                                    subtitle: Text(
                                      itemPrice,
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
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => removeMenuItem(
                                        category,
                                        subcat,
                                        itemName,
                                        itemPrice,
                                      ),
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        );
                      }).toList(),
                    );
                  })
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
