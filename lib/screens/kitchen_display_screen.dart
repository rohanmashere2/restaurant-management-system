import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurant_management/models/order_line_status.dart';

/// Kitchen display: all open order lines across tables for the signed-in manager.
class KitchenDisplayScreen extends StatelessWidget {
  const KitchenDisplayScreen({super.key});

  Future<void> _setLineStatus({
    required String ownerUserId,
    required String table,
    required Map<String, dynamic> line,
    required String newStatus,
  }) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(ownerUserId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = Map<String, dynamic>.from(snap.data() ?? {});
      final addMenu = Map<String, dynamic>.from(data['add_menu'] ?? {});
      final orders = List<dynamic>.from(addMenu[table] ?? []);
      final lineId = line['lineId'] as String?;
      var idx = -1;
      if (lineId != null) {
        idx = orders.indexWhere((o) => o is Map && o['lineId'] == lineId);
      }
      if (idx < 0) {
        final name = line['name']?.toString();
        final note = (line['note'] ?? '').toString().trim();
        idx = orders.indexWhere((o) {
          if (o is! Map) return false;
          return o['name'] == name &&
              (o['note'] ?? '').toString().trim() == note;
        });
      }
      if (idx < 0) return;
      final row = Map<String, dynamic>.from(orders[idx] as Map);
      row['kitchenStatus'] = newStatus;
      orders[idx] = row;
      addMenu[table] = orders;
      tx.update(ref, {'add_menu': addMenu});
    });
  }

  String _nextActionLabel(String status) {
    switch (status) {
      case OrderLineStatus.queued:
        return 'Start';
      case OrderLineStatus.preparing:
        return 'Ready';
      case OrderLineStatus.ready:
        return 'Done';
      default:
        return '';
    }
  }

  String? _nextStatus(String current) {
    switch (current) {
      case OrderLineStatus.queued:
        return OrderLineStatus.preparing;
      case OrderLineStatus.preparing:
        return OrderLineStatus.ready;
      case OrderLineStatus.ready:
        return OrderLineStatus.done;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in as manager to use KDS.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 230, 106, 4),
        title: Text(
          'Kitchen display',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
          final addMenu = Map<String, dynamic>.from(data['add_menu'] ?? {});

          final tiles = <Widget>[];
          for (final tableEntry in addMenu.entries) {
            final table = tableEntry.key.toString();
            final raw = tableEntry.value;
            if (raw is! List) continue;
            for (final o in raw) {
              if (o is! Map) continue;
              final line = Map<String, dynamic>.from(o);
              final status = OrderLineStatus.fromLine(line);
              if (status == OrderLineStatus.done) continue;

              final name = line['name']?.toString() ?? '?';
              final qty = line['quantity'] ?? 1;
              final note = (line['note'] ?? '').toString().trim();
              final next = _nextStatus(status);

              tiles.add(
                Card(
                  color: const Color.fromARGB(255, 230, 106, 4),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                table,
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.w800,
                                  color: const Color.fromARGB(255, 227, 67, 9),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(
                                status.toUpperCase(),
                                style: const TextStyle(fontSize: 11),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$name × $qty',
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (note.isNotEmpty)
                          Text(
                            'Note: $note',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        if (next != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: () => _setLineStatus(
                                ownerUserId: user.uid,
                                table: table,
                                line: line,
                                newStatus: next,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),

                              child: Text(_nextActionLabel(status)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }
          }

          if (tiles.isEmpty) {
            return Center(
              child: Text(
                'No active kitchen tickets.',
                style: GoogleFonts.lato(fontSize: 18),
              ),
            );
          }

          return ListView(children: tiles);
        },
      ),
    );
  }
}
