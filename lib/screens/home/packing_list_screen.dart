import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PackingListScreen extends StatefulWidget {
  final String tripId;
  const PackingListScreen({super.key, required this.tripId});

  @override
  State<PackingListScreen> createState() => _PackingListScreenState();
}

class _PackingListScreenState extends State<PackingListScreen> {
  final _controller = TextEditingController();

  Stream<QuerySnapshot> get _itemsStream => FirebaseFirestore.instance
      .collection('trips')
      .doc(widget.tripId)
      .collection('checklist')
      .orderBy('createdAt')
      .snapshots();

  Future<void> _addItem() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .collection('checklist')
        .add({
      'text':      text,
      'completed': false,
      'addedBy':   uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _controller.clear();
  }

  Future<void> _toggleItem(String id, bool current) async {
    await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .collection('checklist')
        .doc(id)
        .update({'completed': !current});
  }

  Future<void> _deleteItem(String id) async {
    await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .collection('checklist')
        .doc(id)
        .delete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add item input
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFFC8E8D8)),
                onSubmitted: (_) => _addItem(),
                decoration: InputDecoration(
                  hintText: 'Add item (e.g. Passport)',
                  hintStyle: const TextStyle(
                      color: Color(0xFF3A5A4A), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F2820),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF1E3D2E))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF1E3D2E))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF1D9E75), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _addItem,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D9E75), Color(0xFF0D6B52)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),

        // List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _itemsStream,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF1D9E75), strokeWidth: 2),
                );
              }

              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return _emptyState();

              final unchecked =
                  docs.where((d) => !(d['completed'] as bool)).toList();
              final checked =
                  docs.where((d) => d['completed'] as bool).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                children: [
                  ...unchecked.map((d) => _item(d)),
                  if (checked.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('PACKED',
                        style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF3A6A55),
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    ...checked.map((d) => _item(d)),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _item(QueryDocumentSnapshot doc) {
    final completed = doc['completed'] as bool;
    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteItem(doc.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF3B0E0E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFE24B4A)),
      ),
      child: GestureDetector(
        onTap: () => _toggleItem(doc.id, completed),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2820),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: completed
                  ? const Color(0xFF1A3028)
                  : const Color(0xFF1E3D2E),
            ),
          ),
          child: Row(children: [
            // Checkbox
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed
                    ? const Color(0xFF1D9E75)
                    : Colors.transparent,
                border: Border.all(
                  color: completed
                      ? const Color(0xFF1D9E75)
                      : const Color(0xFF3A6A55),
                  width: 1.5,
                ),
              ),
              child: completed
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 12)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                doc['text'] as String,
                style: TextStyle(
                  fontSize: 14,
                  color: completed
                      ? const Color(0xFF3A6A55)
                      : const Color(0xFFE8F5EF),
                  decoration: completed
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF0F2820),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E3D2E)),
          ),
          child: const Icon(Icons.luggage_rounded,
              color: Color(0xFF3A6A55), size: 26),
        ),
        const SizedBox(height: 14),
        const Text('Nothing packed yet',
            style: TextStyle(
                fontSize: 15,
                color: Color(0xFF9AC8B4),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        const Text('Type an item above and tap +',
            style: TextStyle(fontSize: 12, color: Color(0xFF3A5A4A))),
      ],
    ),
  );
}