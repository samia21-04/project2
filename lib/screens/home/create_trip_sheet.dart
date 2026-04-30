import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CreateTripSheet extends StatefulWidget {
  const CreateTripSheet({super.key});
  @override
  State<CreateTripSheet> createState() => _CreateTripSheetState();
}

class _CreateTripSheetState extends State<CreateTripSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedType = 'Beach';
  bool _isLoading = false;

  final _tripTypes = [
    {'label': 'Beach',         'emoji': '🏖️'},
    {'label': 'City',          'emoji': '🏙️'},
    {'label': 'Nature',        'emoji': '🏕️'},
    {'label': 'International', 'emoji': '✈️'},
    {'label': 'Road Trip',     'emoji': '🚗'},
    {'label': 'Other',         'emoji': '🗺️'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? now)
          : (_endDate ?? _startDate ?? now),
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF1D9E75),
            surface: Color(0xFF0F2820),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select start and end dates')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('trips').add({
        'name':          _nameController.text.trim(),
        'destination':   _destinationController.text.trim(),
        'startDate':     Timestamp.fromDate(_startDate!),
        'endDate':       Timestamp.fromDate(_endDate!),
        'tripType':      _selectedType,
        'ownerUid':      uid,
        'collaborators': [uid],
        'createdAt':     FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1F18),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF1E3D2E))),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36, height: 3,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3D2E),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                const Text('New Trip',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE8F5EF))),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2820),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1E3D2E)),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Color(0xFF5A8A76), size: 16),
                  ),
                ),
              ]),
            ),
            // Form body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Trip name'),
                    _textField(
                      controller: _nameController,
                      hint: 'e.g. Summer Getaway',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    _label('Destination'),
                    _textField(
                      controller: _destinationController,
                      hint: 'e.g. Clearwater Beach, FL',
                      prefixIcon: Icons.location_on_outlined,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    _label('Dates'),
                    Row(children: [
                      Expanded(
                        child: _datePicker(
                          label: _startDate != null
                              ? fmt.format(_startDate!)
                              : 'Start date',
                          onTap: () => _pickDate(isStart: true),
                          filled: _startDate != null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _datePicker(
                          label: _endDate != null
                              ? fmt.format(_endDate!)
                              : 'End date',
                          onTap: () => _pickDate(isStart: false),
                          filled: _endDate != null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),

                    _label('Trip type'),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2.2,
                      children: _tripTypes.map((t) {
                        final sel = _selectedType == t['label'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedType = t['label']!),
                          child: Container(
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFF0D2518)
                                  : const Color(0xFF0F2820),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: sel
                                    ? const Color(0xFF1D9E75)
                                    : const Color(0xFF1E3D2E),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(t['emoji']!,
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(t['label']!,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: sel
                                            ? const Color(0xFF1D9E75)
                                            : const Color(0xFF5A8A76))),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D9E75),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Create Trip',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF5A8A76),
            letterSpacing: 1.0,
            fontWeight: FontWeight.w500)),
  );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        validator: validator,
        style: const TextStyle(fontSize: 14, color: Color(0xFFC8E8D8)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFF3A5A4A), fontSize: 13),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon,
                  color: const Color(0xFF3A6A55), size: 18)
              : null,
          filled: true,
          fillColor: const Color(0xFF0F2820),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E3D2E))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E3D2E))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF1D9E75), width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF7A1F1F))),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 13),
        ),
      );

  Widget _datePicker({
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2820),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: filled
                  ? const Color(0xFF1D9E75)
                  : const Color(0xFF1E3D2E),
            ),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today_rounded,
                size: 13,
                color: filled
                    ? const Color(0xFF1D9E75)
                    : const Color(0xFF3A6A55)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: filled
                          ? const Color(0xFFC8E8D8)
                          : const Color(0xFF3A5A4A))),
            ),
          ]),
        ),
      );
}