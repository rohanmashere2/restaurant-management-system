import 'package:restaurant_management/models/menu.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenuAddScreen extends StatefulWidget {
  const MenuAddScreen({super.key});

  @override
  State<MenuAddScreen> createState() => MenuAddScreenState();
}

class MenuAddScreenState extends State<MenuAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  String? _category;
  String? _subCategory;
  final Map<String, List<String>> _categories = {
    'Veg': ['Starters', 'Main Menu', 'Rice & Biryani', 'Roti', 'Cold Drinks'],
    'Non-Veg': [
      'Starters',
      'Main Menu',
      'Rice & Biryani',
      'Roti',
      'Cold Drinks',
    ],
  };

  Future<void> addMenuItem({
    required String userId,
    required String category,
    required String subCategory,
    required MenuItem menuItem,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final docSnapshot = await docRef.get();
    Map<String, dynamic> menu = docSnapshot.data()?['menu'] ?? {};

    if (!menu.containsKey(category)) {
      menu[category] = {};
    }
    if (!menu[category].containsKey(subCategory)) {
      menu[category][subCategory] = [];
    }

    (menu[category][subCategory] as List).add(menuItem.toMap());
    await docRef.update({'menu': menu});
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final String name = _nameController.text;
      final double price = double.parse(_priceController.text);

      if (_category != null && _subCategory != null) {
        final menuItem = MenuItem(name: name, price: price);

        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('User is not signed in')));
            return;
          }

          await addMenuItem(
            userId: user.uid,
            category: _category!,
            subCategory: _subCategory!,
            menuItem: menuItem,
          );

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Item added successfully!')));

          _nameController.clear();
          _priceController.clear();
          setState(() {
            _category = null;
            _subCategory = null;
          });
          Navigator.of(context).pop();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add menu item: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 230, 106, 4),
        title: Text(
          'Add Item',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu, color: Color.fromARGB(255, 90, 57, 44)),
                      SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Item Name',
                            labelStyle: GoogleFonts.lato(
                              fontSize: 18,
                              color: Color.fromARGB(255, 140, 93, 74),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the menu item name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.currency_rupee,
                        color: Color.fromARGB(255, 90, 57, 44),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Price',
                            labelStyle: GoogleFonts.lato(
                              fontSize: 18,
                              color: Color.fromARGB(255, 140, 93, 74),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid price';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    dropdownColor: Color.fromARGB(255, 249, 111, 5),
                    initialValue: _category,
                    hint: Text(
                      'Category',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        color: Color.fromARGB(255, 140, 93, 74),
                      ),
                    ),
                    decoration: InputDecoration(
                      icon: Icon(
                        Icons.category,
                        color: Color.fromARGB(255, 90, 57, 44),
                      ),
                    ),
                    items: _categories.keys.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: GoogleFonts.lato(fontSize: 18),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _category = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    dropdownColor: Color.fromARGB(255, 249, 111, 5),
                    initialValue: _subCategory,
                    hint: Text(
                      'Sub-Category',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        color: Color.fromARGB(255, 140, 93, 74),
                      ),
                    ),
                    decoration: InputDecoration(
                      icon: Icon(
                        Icons.category_outlined,
                        color: Color.fromARGB(255, 90, 57, 44),
                      ),
                    ),
                    items:
                        (_category != null ? _categories[_category!] ?? [] : [])
                            .map((subCategory) {
                              return DropdownMenuItem<String>(
                                value: subCategory,
                                child: Text(
                                  subCategory,
                                  style: GoogleFonts.lato(fontSize: 18),
                                ),
                              );
                            })
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _subCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a sub-category';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 249, 111, 5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 90,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        'Add Item',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
