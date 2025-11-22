import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

class ManagerCheckoutScreen extends StatefulWidget {
  final String table;
  const ManagerCheckoutScreen({super.key, required this.table});

  @override
  State<ManagerCheckoutScreen> createState() => ManagerCheckoutScreenState();
}

class ManagerCheckoutScreenState extends State<ManagerCheckoutScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  bool isGeneratingBill = false;

  Future<Map<String, dynamic>> fetchOrderDetails(
    String userId,
    String table,
  ) async {
    try {
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      final userDocSnapshot = await userDocRef.get();
      if (userDocSnapshot.exists) {
        final userData = userDocSnapshot.data() as Map<String, dynamic>;

        final addMenu = userData['add_menu'] ?? {};
        final totalBill = userData['total_bill'] ?? {};

        final tableOrders = List<Map<String, dynamic>>.from(
          addMenu[table] ?? [],
        );
        final tableTotalBill = totalBill[table] ?? 0.0;

        return {'orders': tableOrders, 'total_bill': tableTotalBill};
      } else {
        return {'orders': [], 'total_bill': 0.0};
      }
    } catch (e) {
      return {'orders': [], 'total_bill': 0.0};
    }
  }

  Future<String> getRestaurantName() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return userDoc.data()?['Restaurant Name'] ?? 'No Restaurant';
  }

  Future<String> getAddress() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return userDoc.data()?['Address'] ?? 'No Address';
  }

  Future<String> getMobileNO() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return userDoc.data()?['Mobile No'] ?? 'No Mobile no';
  }

  Future<String> getEmail() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return userDoc.data()?['Email'] ?? 'No Email';
  }

  Future<String> getAndIncrementInvoiceNumber() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      return await FirebaseFirestore.instance.runTransaction((
        transaction,
      ) async {
        final docSnapshot = await transaction.get(docRef);

        int newInvoiceNumber;
        if (!docSnapshot.exists) {
          transaction.set(docRef, {'current_invoice_number': 1});
          newInvoiceNumber = 1;
        } else {
          final currentInvoiceNumber =
              docSnapshot.data()?['current_invoice_number'] ?? 0;

          newInvoiceNumber = currentInvoiceNumber + 1;
          transaction.update(docRef, {
            'current_invoice_number': newInvoiceNumber,
          });
        }

        return 'IN${newInvoiceNumber.toString().padLeft(3, '0')}';
      });
    } catch (e) {
      return 'IN000';
    }
  }

  Future<void> clearTableData(String userId, String table) async {
    try {
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDocSnapshot = await transaction.get(userDocRef);

        if (userDocSnapshot.exists) {
          final currentData = userDocSnapshot.data() as Map<String, dynamic>;
          Map<String, dynamic> updatedAddMenu = Map.from(
            currentData['add_menu'] ?? {},
          );
          Map<String, dynamic> updatedTotalBill = Map.from(
            currentData['total_bill'] ?? {},
          );

          updatedAddMenu.remove(table);
          updatedTotalBill.remove(table);

          transaction.update(userDocRef, {
            'add_menu': updatedAddMenu,
            'total_bill': updatedTotalBill,
          });
        }
      });
    } catch (e) {}
  }

  Future<void> generateAndViewBill(
    Map<String, dynamic> orderDetails,
    String restaurantName,
    String address,
    String mobileNo,
    String email,
  ) async {
    setState(() {
      isGeneratingBill = true;
    });

    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final date = '${now.day}/${now.month}/${now.year}';
      final latoRegular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Lato-Regular.ttf'),
      );
      if (orderDetails.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No items in the order. Cannot generate the bill.'),
          ),
        );
        return;
      }

      final invoiceNumber = await getAndIncrementInvoiceNumber();

      final orders = orderDetails['orders'] as List<Map<String, dynamic>>;
      final totalBill = orderDetails['total_bill'] as double;

      final cgst = totalBill * 0.0;
      final sgst = totalBill * 0.0;
      final serviceTax = totalBill * 0.0;
      final grandTotal = totalBill + cgst + sgst + serviceTax;
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await storeBillFor5Minutes(invoiceNumber, grandTotal);
      }
      await clearTableData(user!.uid, widget.table);

      List<String> itemNames = [];
      List<int> itemQuantities = [];
      List<double> itemRates = [];
      List<double> itemTotals = [];
      final labels = [
        'Total Qty.',
        'Subtotal',
        'CGST',
        'SGST',
        'Service Tax',
        'Total Bill',
      ];
      final totalQuantity = orders.isNotEmpty
          ? orders.map((order) => order['quantity']).reduce((a, b) => a + b)
          : 0;

      final data = [
        totalQuantity,
        'Rs ${totalBill.toStringAsFixed(2)}',
        'Rs ${cgst.toStringAsFixed(2)}',
        'Rs ${sgst.toStringAsFixed(2)}',
        'Rs ${serviceTax.toStringAsFixed(2)}',
        'Rs ${grandTotal.toStringAsFixed(2)}',
      ];

      for (var order in orders) {
        itemNames.add(order['name']);
        itemQuantities.add(order['quantity']);
        itemRates.add(order['price']);
        itemTotals.add(order['quantity'] * order['price']);
      }

      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    restaurantName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 23,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    address,
                    style: pw.TextStyle(fontSize: 18),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Center(
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'Email: ',
                          style: pw.TextStyle(fontSize: 18),
                        ),
                        pw.TextSpan(
                          text: email,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'Mobile No: ',
                          style: pw.TextStyle(fontSize: 18),
                        ),
                        pw.TextSpan(
                          text: mobileNo,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Invoice No: ',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                      pw.TextSpan(
                        text: invoiceNumber,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Invoice Date: ',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                      pw.TextSpan(
                        text: date,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    widget.table.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 23,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Center(child: _dottedDivider()),
                pw.SizedBox(height: 10),
                pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      children: [
                        pw.SizedBox(width: 80),
                        pw.Text(
                          "Item",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 19,
                          ),
                        ),
                        pw.SizedBox(width: 120),
                        pw.Text(
                          "Qty",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 19,
                          ),
                        ),
                        pw.SizedBox(width: 90),
                        pw.Text(
                          "Rate",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 19,
                          ),
                        ),
                        pw.SizedBox(width: 70),
                        pw.Text(
                          "Total",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 19,
                          ),
                        ),
                      ],
                    ),
                    pw.Center(child: _dottedDivider()),
                    ...List.generate(itemNames.length, (index) {
                      return pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.SizedBox(width: 20),
                          pw.Expanded(
                            flex: 2,
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(
                                    text: '${index + 1}.   ',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 15,
                                      font: latoRegular,
                                    ),
                                  ),
                                  pw.TextSpan(
                                    text: itemNames[index],
                                    style: pw.TextStyle(
                                      fontSize: 15,
                                      font: latoRegular,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 25),
                          pw.Expanded(
                            child: pw.Text(
                              '${itemQuantities[index]}',
                              style: pw.TextStyle(
                                fontSize: 15,
                                font: latoRegular,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              'Rs ${itemRates[index].toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                fontSize: 15,
                                font: latoRegular,
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          pw.Expanded(
                            child: pw.Text(
                              'Rs ${(itemTotals[index]).toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                fontSize: 15,
                                font: latoRegular,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.Center(child: _dottedDivider()),
                pw.SizedBox(height: 20),
                ...List.generate(labels.length - 1, (index) {
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.SizedBox(width: 70),
                      pw.Expanded(
                        child: pw.Text(
                          '${labels[index]}:',
                          style: pw.TextStyle(fontSize: 14, font: latoRegular),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Text(
                              data[index].toString(),
                              style: pw.TextStyle(
                                fontSize: 14,
                                font: latoRegular,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 20),
                    ],
                  );
                }),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.SizedBox(width: 70),
                    pw.Text(
                      'Total Bill:',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(width: 240),
                    pw.Text(
                      data.last.toString(),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Center(
                  child: pw.Text(
                    'Thank You For Visiting!',
                    style: pw.TextStyle(fontSize: 17, font: latoRegular),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/bill_${widget.table}.pdf');
      await file.writeAsBytes(await pdf.save());

      Printing.layoutPdf(onLayout: (format) => pdf.save());
    } finally {
      setState(() {
        isGeneratingBill = false;
      });
    }
  }

  Future<void> storeBillFor5Minutes(
    String invoiceNumber,
    double totalBill,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return;
    }

    final databaseRef = FirebaseDatabase.instance.ref();
    final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now();
    final currentDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final billData = {
      "invoice_no": invoiceNumber,
      "total_bill": totalBill,
      "timestamp": currentTimestamp,
    };

    final billRef = databaseRef.child("users/$userId/bills/$currentDate");

    final snapshot = await billRef.get();

    if (snapshot.exists) {
      List<dynamic> existingBills;
      if (snapshot.value is List) {
        existingBills = List<dynamic>.from(snapshot.value as List);
      } else {
        throw Exception("Unexpected data structure: expected a list.");
      }

      existingBills.add(billData);
      await billRef.set(existingBills);
    } else {
      await billRef.set([billData]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '${widget.table} - Checkout',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 230, 106, 4),
      ),
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, orderSnapshot) {
              if (orderSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!orderSnapshot.hasData || orderSnapshot.data == null) {
                return const Center(child: Text('No orders for this table.'));
              }

              final data =
                  orderSnapshot.data!.data() as Map<String, dynamic>? ?? {};

              // ----------- FIX: SAFE NULL HANDLING -----------
              final addMenu = data['add_menu'] ?? {};
              final totalBillMap = data['total_bill'] ?? {};

              final orders = List<Map<String, dynamic>>.from(
                addMenu[widget.table] ?? [],
              );

              final totalBill = totalBillMap[widget.table] ?? 0.0;

              Map<String, List<Map<String, dynamic>>> groupedOrders = {};

              for (var order in orders) {
                String category = order['category'] ?? 'Uncategorized';
                if (groupedOrders.containsKey(category)) {
                  groupedOrders[category]!.add(order);
                } else {
                  groupedOrders[category] = [order];
                }
              }

              return ListView(
                padding: EdgeInsets.all(10),
                children: [
                  Text(
                    'Order Summary',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(),
                  if (orders.isEmpty)
                    Center(
                      child: Text(
                        'No items Added',
                        style: GoogleFonts.lato(fontSize: 18),
                      ),
                    ),
                  ...groupedOrders.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ...entry.value.map((order) {
                          return ListTile(
                            title: Text(
                              '${order['name']} x ${order['quantity']}',
                              style: GoogleFonts.lato(
                                fontSize: 18,
                                color: Color.fromARGB(255, 90, 57, 44),
                              ),
                            ),
                            subtitle: Text(
                              'Rs ${order['price']}',
                              style: GoogleFonts.lato(
                                color: Color.fromARGB(255, 90, 57, 44),
                              ),
                            ),
                          );
                        }),
                        Divider(),
                      ],
                    );
                  }),
                  Text(
                    'Total Bill: Rs $totalBill',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              );
            },
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: isGeneratingBill
                    ? null
                    : () async {
                        final orderDetails = await fetchOrderDetails(
                          user.uid,
                          widget.table,
                        );
                        final restaurantName = await getRestaurantName();
                        final address = await getAddress();
                        final mobileNo = await getMobileNO();
                        final email = await getEmail();
                        if (orderDetails['total_bill'] == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'No items in the order. Cannot generate the bill.',
                              ),
                            ),
                          );
                          return;
                        } else {
                          await generateAndViewBill(
                            orderDetails,
                            restaurantName,
                            address,
                            mobileNo,
                            email,
                          );
                          setState(() {});
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 230, 106, 4),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Checkout',
                      style: GoogleFonts.lato(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

pw.Widget _dottedDivider() {
  return pw.Text(
    "." * 80,
    style: pw.TextStyle(fontSize: 25, color: PdfColors.black),
    textAlign: pw.TextAlign.center,
  );
}
