import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/activity.dart';

class OptimizerResultScreen extends StatefulWidget {
  final String tripId;
  final List<Activity> sorted;
  final List<Activity> original;

  const OptimizerResultScreen({
    super.key,
    required this.tripId,
    required this.sorted,
    required this.original,
  });

  @override
  State<OptimizerResultScreen> createState() => _OptimizerResultScreenState();
}

class _OptimizerResultScreenState extends State<OptimizerResultScreen> {
  bool _isLoading = false;

  bool _positionChanged(Activity act, int newIndex) {
    final oldIndex =
        widget.original.indexWhere((a) => a.id == act.id);
    return oldIndex != newIndex;
  }

  Future<void> _acceptOrder() async {
    setState(() => _isLoading = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final colRef = FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .collection('activities');

      // Re-write startTime with padded index to preserve order
      for (int i = 0; i < widget.sorted.length; i++) {
        final act = widget.sorted[i];
        batch.update(colRef.doc(act.id), {'startTime': act.startTime});
      }
      await batch.commit();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F18),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2820),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1E3D2E)),
                    ),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: Color(0xFF5A8A76), size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Optimized Itinerary',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE8F5EF))),
                      Text('Sorted by start time',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF4D7A6A))),
                    ],
                  ),
                ),
              ]),
            ),

            // Info box
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2518),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1D9E75)),
                ),
                child: const Row(children: [
                  Icon(Icons.auto_graph_rounded,
                      color: Color(0xFF1D9E75), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Activities reordered by start time. Items marked "Moved" changed position.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9AC8B4),
                          height: 1.4),
                    ),
                  ),
                ]),
              ),
            ),

            // Sorted list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                itemCount: widget.sorted.length,
                itemBuilder: (ctx, i) {
                  final act = widget.sorted[i];
                  final moved = _positionChanged(act, i);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2820),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: moved
                            ? const Color(0xFF1D9E75).withOpacity(0.5)
                            : const Color(0xFF1E3D2E),
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 6, height: 6,
                        margin: const EdgeInsets.only(right: 10, top: 2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1D9E75),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(act.name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFE8F5EF))),
                              ),
                              Text(act.startTime,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF1D9E75),
                                      fontWeight: FontWeight.w500)),
                            ]),
                            if (moved) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D2518),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: const Color(0xFF1D9E75)
                                          .withOpacity(0.4)),
                                ),
                                child: const Text('Moved · Sorted by time',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF1D9E75))),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ]),
                  );
                },
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF1E3D2E)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(color: Color(0xFF5A8A76))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _acceptOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D9E75),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Accept Order',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}