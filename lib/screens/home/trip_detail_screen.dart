import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/trip.dart';
import '../../models/activity.dart';
import 'add_activity_screen.dart';
import 'packing_list_screen.dart';
import 'invite_collaborator_screen.dart';
import 'optimizer_result_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Activity>> get _activitiesStream =>
      FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.trip.id)
          .collection('activities')
          .orderBy('startTime')
          .snapshots()
          .map((s) => s.docs.map((d) => Activity.fromDoc(d)).toList());

  Future<void> _deleteActivity(String actId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F2820),
        title: const Text('Delete activity?',
            style: TextStyle(color: Color(0xFFE8F5EF))),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: Color(0xFF4D7A6A))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF5A8A76)))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Color(0xFFE24B4A)))),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id)
        .collection('activities')
        .doc(actId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d');
    final dateRange =
        '${fmt.format(widget.trip.startDate)} – ${fmt.format(widget.trip.endDate)}';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F18),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A2018), Color(0xFF0D1F18)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _iconBtn(Icons.chevron_left_rounded,
                        onTap: () => Navigator.pop(context)),
                    const Spacer(),
                    _iconBtn(Icons.person_add_outlined, onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InviteCollaboratorScreen(
                              tripId: widget.trip.id),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    _iconBtn(Icons.more_horiz_rounded, onTap: () {}),
                  ]),
                  const SizedBox(height: 12),
                  Text(widget.trip.destination,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE8F5EF))),
                  const SizedBox(height: 2),
                  Text('${widget.trip.name} · $dateRange',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF4D7A6A))),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, children: [
                    _chip(Icons.people_outline_rounded,
                        '${widget.trip.collaborators.length} traveler${widget.trip.collaborators.length > 1 ? 's' : ''}'),
                    _chip(null, widget.trip.tripType),
                  ]),
                ],
              ),
            ),

            // Tab bar
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF1D9E75),
              indicatorWeight: 2,
              labelColor: const Color(0xFF1D9E75),
              unselectedLabelColor: const Color(0xFF3A6A55),
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
              dividerColor: const Color(0xFF1A3028),
              tabs: const [
                Tab(text: 'Activities'),
                Tab(text: 'Packing List'),
              ],
            ),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _activitiesTab(),
                  PackingListScreen(tripId: widget.trip.id),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AddActivityScreen(tripId: widget.trip.id),
          ),
        ),
        backgroundColor: const Color(0xFF1D9E75),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        child:
            const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _activitiesTab() {
    return StreamBuilder<List<Activity>>(
      stream: _activitiesStream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF1D9E75), strokeWidth: 2));
        }
        final activities = snap.data ?? [];
        if (activities.isEmpty) return _emptyActivities();

        return Column(
          children: [
            // Optimize button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: GestureDetector(
                onTap: () {
                  final sorted = [...activities]
                    ..sort((a, b) =>
                        a.startTime.compareTo(b.startTime));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OptimizerResultScreen(
                        tripId: widget.trip.id,
                        sorted: sorted,
                        original: activities,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2518),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF1D9E75)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.auto_graph_rounded,
                        color: Color(0xFF1D9E75), size: 15),
                    SizedBox(width: 8),
                    Text('Optimize itinerary',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1D9E75),
                            fontWeight: FontWeight.w500)),
                    Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF1D9E75), size: 16),
                  ]),
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: activities.length,
                itemBuilder: (ctx, i) =>
                    _activityCard(activities[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _activityCard(Activity act) {
    return Dismissible(
      key: Key(act.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _deleteActivity(act.id);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF3B0E0E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFE24B4A)),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddActivityScreen(
                tripId: widget.trip.id, existing: act),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2820),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: const Color(0xFF1E3D2E)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5, right: 10),
                width: 6, height: 6,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1D9E75)),
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
                    const SizedBox(height: 5),
                    Wrap(spacing: 5, runSpacing: 4, children: [
                      _actChip(act.category),
                      if (act.location.isNotEmpty)
                        _actChip(act.location),
                      if (act.estimatedBudget > 0)
                        _actChip(
                            '\$${act.estimatedBudget.toStringAsFixed(0)}'),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actChip(String label) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFF0A1A14),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: const Color(0xFF1A3028)),
    ),
    child: Text(label,
        style: const TextStyle(
            fontSize: 10, color: Color(0xFF4D7A6A))),
  );

  Widget _emptyActivities() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
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
            child: const Icon(Icons.map_outlined,
                color: Color(0xFF3A6A55), size: 24),
          ),
          const SizedBox(height: 14),
          const Text('No activities yet',
              style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF9AC8B4),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('Tap + to add your first activity.',
              style: TextStyle(
                  fontSize: 12, color: Color(0xFF3A5A4A))),
        ],
      ),
    ),
  );

  Widget _iconBtn(IconData icon, {required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF0F2820),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1E3D2E)),
          ),
          child: Icon(icon,
              color: const Color(0xFF5A8A76), size: 18),
        ),
      );

  Widget _chip(IconData? icon, String label) => Container(
    padding:
        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF0A1A14),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFF1A3028)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[
        Icon(icon, size: 10, color: const Color(0xFF5A8A76)),
        const SizedBox(width: 4),
      ],
      Text(label,
          style: const TextStyle(
              fontSize: 10, color: Color(0xFF5A8A76))),
    ]),
  );
}