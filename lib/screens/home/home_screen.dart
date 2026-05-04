import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'create_trip_sheet.dart';
import 'trip_detail_screen.dart';
import '../../models/trip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  bool _searchActive = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _firstName {
    final name = FirebaseAuth.instance.currentUser?.displayName ?? '';
    return name.split(' ').first.isEmpty ? 'Traveler' : name.split(' ').first;
  }

  Stream<List<Trip>> get _tripsStream {
    return FirebaseFirestore.instance
        .collection('trips')
        .where('collaborators', arrayContains: _uid)
        .orderBy('startDate')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Trip.fromDoc(d)).toList());
  }

  List<Trip> _filterTrips(List<Trip> trips) {
    if (_searchQuery.isEmpty) return trips;
    final q = _searchQuery.toLowerCase();
    return trips.where((t) {
      return t.name.toLowerCase().contains(q) ||
          t.destination.toLowerCase().contains(q) ||
          t.tripType.toLowerCase().contains(q);
    }).toList();
  }

  void _openCreateTrip() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateTripSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F18),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: _searchActive ? _searchBar() : _topBar(),
            ),

            // Trip list
            Expanded(
              child: StreamBuilder<List<Trip>>(
                stream: _tripsStream,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF1D9E75), strokeWidth: 2));
                  }
                  final allTrips = snap.data ?? [];
                  final trips = _filterTrips(allTrips);

                  if (allTrips.isEmpty) return _emptyState();

                  if (trips.isEmpty && _searchQuery.isNotEmpty) {
                    return _noResultsState();
                  }

                  final now = DateTime.now();
                  final upcoming =
                      trips.where((t) => !t.endDate.isBefore(now)).toList();
                  final past =
                      trips.where((t) => t.endDate.isBefore(now)).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    children: [
                      if (upcoming.isNotEmpty) ...[
                        _sectionLabel('Upcoming'),
                        ...upcoming.map((t) => _tripCard(t, past: false)),
                      ],
                      if (past.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _sectionLabel('Past'),
                        ...past.map((t) => _tripCard(t, past: true)),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTrip,
        backgroundColor: const Color(0xFF1D9E75),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
      ),

      bottomNavigationBar: _bottomNav(),
    );
  }

  // ── Top bar & Search ───────────────────────────────────────────────────

  Widget _topBar() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Trips',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE8F5EF))),
              Text('Hey, $_firstName 👋  Where to next?',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF4D7A6A))),
            ],
          ),
        ),
        _iconBtn(Icons.search_rounded, onTap: () {
          setState(() => _searchActive = true);
        }),
      ],
    );
  }

  Widget _searchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0F2820),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1D9E75)),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(fontSize: 14, color: Color(0xFFE8F5EF)),
              decoration: const InputDecoration(
                hintText: 'Search trips...',
                hintStyle: TextStyle(color: Color(0xFF3A5A4A), fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Color(0xFF3A6A55), size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            setState(() {
              _searchActive = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
          child: const Text('Cancel',
              style: TextStyle(fontSize: 13, color: Color(0xFF1D9E75))),
        ),
      ],
    );
  }

  Widget _noResultsState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF0F2820),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1E3D2E)),
            ),
            child: const Icon(Icons.search_off_rounded,
                color: Color(0xFF3A6A55), size: 28),
          ),
          const SizedBox(height: 16),
          const Text('No trips found',
              style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF9AC8B4),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('Try searching by destination, name, or trip type.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF3A5A4A),
                  height: 1.5)),
        ],
      ),
    ),
  );

  // ── Widgets ────────────────────────────────────────────────────────────

  Widget _tripCard(Trip trip, {required bool past}) {
    final fmt = DateFormat('MMM d');
    final dateRange =
        '${fmt.format(trip.startDate)} – ${fmt.format(trip.endDate)}';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2820),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E3D2E)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Accent bar
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: past
                      ? const Color(0xFF3A5A4A)
                      : const Color(0xFF1D9E75),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(trip.destination,
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: past
                                            ? const Color(0xFF6A9A82)
                                            : const Color(0xFFE8F5EF))),
                                Text(trip.name,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF4D7A6A))),
                              ],
                            ),
                          ),
                          // Collaborator count badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A1A14),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: const Color(0xFF1A3028)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_outline_rounded,
                                    size: 10,
                                    color: Color(0xFF5A8A76)),
                                const SizedBox(width: 4),
                                Text(
                                    '${trip.collaborators.length}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF5A8A76))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        _chip(Icons.calendar_today_rounded, dateRange),
                        _chip(null, trip.tripType),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData? icon, String label) {
    return Container(
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

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF3A6A55),
            letterSpacing: 1.2,
            fontWeight: FontWeight.w500)),
  );

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF0F2820),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1E3D2E)),
            ),
            child: const Icon(Icons.luggage_rounded,
                color: Color(0xFF3A6A55), size: 28),
          ),
          const SizedBox(height: 16),
          const Text('No trips yet',
              style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF9AC8B4),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text(
            'Tap + to create your first trip\nand invite a travel partner.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color: Color(0xFF3A5A4A),
                height: 1.5),
          ),
        ],
      ),
    ),
  );

  Widget _iconBtn(IconData icon, {required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF0F2820),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1E3D2E)),
          ),
          child: Icon(icon, color: const Color(0xFF5A8A76), size: 18),
        ),
      );

  Widget _bottomNav() => Container(
    height: 64,
    decoration: const BoxDecoration(
      color: Color(0xFF0A1510),
      border: Border(top: BorderSide(color: Color(0xFF1A3028))),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _navItem(Icons.home_rounded, 'Trips', 0),
        _navItem(Icons.person_outline_rounded, 'Profile', 1),
      ],
    ),
  );

  Widget _navItem(IconData icon, String label, int index) {
    final active = index == 0;
    return GestureDetector(
      onTap: () {
        if (index == 1) Navigator.pushNamed(context, '/profile');
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF0F2820)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              color: active
                  ? const Color(0xFF1D9E75)
                  : const Color(0xFF3A6A55),
              size: 20),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: active
                      ? const Color(0xFF1D9E75)
                      : const Color(0xFF3A6A55))),
        ]),
      ),
    );
  }
}