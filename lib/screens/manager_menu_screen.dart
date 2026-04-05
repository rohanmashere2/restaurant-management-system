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

  double _parsePriceFromSubtitle(String itemPrice) {
    return double.tryParse(itemPrice.replaceAll('Rs ', '').trim()) ?? 0.0;
  }

  Future<void> removeMenuItem(
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

            double priceToRemove = _parsePriceFromSubtitle(itemPrice);

            items.removeWhere(
              (item) =>
                  item['name'] == itemName && item['price'] == priceToRemove,
            );

            subcategories[subcategory] = items;
          }
        }

        await userDocRef.update({'menu': updatedMenu});
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item removed')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not remove item: $e')));
    }
  }

  Future<void> setItemAvailable({
    required String category,
    required String subcategory,
    required String itemName,
    required double price,
    required bool available,
  }) async {
    try {
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId);
      final snap = await userDocRef.get();
      final menu = Map<String, dynamic>.from(snap.data()?['menu'] ?? {});
      final sub = Map<String, dynamic>.from(menu[category] ?? {});
      final items = List<dynamic>.from(sub[subcategory] ?? []);

      final idx = items.indexWhere(
        (it) =>
            it['name'] == itemName && (it['price'] as num).toDouble() == price,
      );
      if (idx < 0) return;

      final row = Map<String, dynamic>.from(items[idx] as Map);
      row['available'] = available;
      items[idx] = row;
      sub[subcategory] = items;
      menu[category] = sub;
      await userDocRef.update({'menu': menu});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update availability: $e')),
      );
    }
  }

  Future<void> showEditMenuItemDialog({
    required String category,
    required String subcategory,
    required Map<String, dynamic> item,
  }) async {
    final nameCtrl = TextEditingController(
      text: item['name']?.toString() ?? '',
    );
    final priceCtrl = TextEditingController(
      text: (item['price'] as num?)?.toString() ?? '',
    );
    var available = item['available'] != false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(255, 230, 106, 4),
            title: Text(
              'Edit Item',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: GoogleFonts.lato(color: Colors.white),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    controller: priceCtrl,
                    decoration: InputDecoration(
                      labelText: 'Price',
                      labelStyle: GoogleFonts.lato(color: Colors.white),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Available on waiter menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: available,
                    onChanged: (v) => setDlg(() => available = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              FilledButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 68, 20, 2),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true || !mounted) {
      nameCtrl.dispose();
      priceCtrl.dispose();
      return;
    }

    final newName = nameCtrl.text.trim();
    final newPrice = double.tryParse(priceCtrl.text.trim());
    nameCtrl.dispose();
    priceCtrl.dispose();

    if (newName.isEmpty || newPrice == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid name or price')));
      return;
    }

    final oldName = item['name'] as String;
    final oldPrice = (item['price'] as num).toDouble();

    try {
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId);
      final snap = await userDocRef.get();
      final menu = Map<String, dynamic>.from(snap.data()?['menu'] ?? {});
      final sub = Map<String, dynamic>.from(menu[category] ?? {});
      final items = List<dynamic>.from(sub[subcategory] ?? []);

      final idx = items.indexWhere(
        (it) =>
            it['name'] == oldName &&
            (it['price'] as num).toDouble() == oldPrice,
      );
      if (idx < 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item not found (maybe changed).')),
        );
        return;
      }

      items[idx] = {'name': newName, 'price': newPrice, 'available': available};
      sub[subcategory] = items;
      menu[category] = sub;
      await userDocRef.update({'menu': menu});
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Menu item updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
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
                                final priceVal =
                                    (item['price'] as num?)?.toDouble() ?? 0.0;
                                final available = item['available'] != false;

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
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
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
                                        if (!available)
                                          Text(
                                            '86 / hidden from waiter',
                                            style: GoogleFonts.lato(
                                              fontSize: 12,
                                              color: Colors.red.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Tooltip(
                                          message: 'Available on waiter menu',
                                          child: Transform.scale(
                                            scale: 0.85,
                                            child: Switch(
                                              value: available,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              onChanged: (v) =>
                                                  setItemAvailable(
                                                    category: category,
                                                    subcategory: subcat,
                                                    itemName: itemName,
                                                    price: priceVal,
                                                    available: v,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Color.fromARGB(
                                              255,
                                              90,
                                              57,
                                              44,
                                            ),
                                          ),
                                          onPressed: () =>
                                              showEditMenuItemDialog(
                                                category: category,
                                                subcategory: subcat,
                                                item: Map<String, dynamic>.from(
                                                  item,
                                                ),
                                              ),
                                        ),
                                        IconButton(
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
                                      ],
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
