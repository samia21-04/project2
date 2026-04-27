import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/activity.dart';

class AddActivityScreen extends StatefulWidget {
  final String tripId;
  final Activity? existing; // null = create, non-null = edit

  const AddActivityScreen({
    super.key,
    required this.tripId,
    this.existing,
  });

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _budgetController;
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCategory = 'Sightseeing';
  bool _isLoading = false;

  final _categories = [
    'Food', 'Sightseeing', 'Transport', 'Hotel', 'Activity', 'Other'
  ];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController     = TextEditingController(text: e?.name ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _budgetController   = TextEditingController(
        text: e != null && e.estimatedBudget > 0
            ? e.estimatedBudget.toStringAsFixed(0)
            : '');
    if (e != null) {
      _selectedCategory = e.category;
      final parts = e.startTime.split(':');
      if (parts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .collection('activities');

    final data = {
      'name':            _nameController.text.trim(),
      'startTime':       _formatTime(_selectedTime),
      'location':        _locationController.text.trim(),
      'estimatedBudget': double.tryParse(_budgetController.text) ?? 0,
      'category':        _selectedCategory,
      'addedBy':         uid,
    };

    try {
      if (_isEditing) {
        await ref.doc(widget.existing!.id).update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await ref.add(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving activity: $e')),
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  _iconBtn(Icons.chevron_left_rounded,
                      onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Text(
                    _isEditing ? 'Edit Activity' : 'Add Activity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE8F5EF),
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Activity name'),
                      _textField(
                        controller: _nameController,
                        hint: 'e.g. Sunset dinner',
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      _label('Start time'),
                      GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F2820),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF1E3D2E)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.access_time_rounded,
                                color: Color(0xFF3A6A55), size: 18),
                            const SizedBox(width: 10),
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFFC8E8D8)),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('Location (optional)'),
                      _textField(
                        controller: _locationController,
                        hint: 'e.g. Shephard\'s Resort',
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 16),

                      _label('Estimated budget (\$)'),
                      _textField(
                        controller: _budgetController,
                        hint: '0',
                        prefixIcon: Icons.attach_money_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      _label('Category'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((cat) {
                          final sel = _selectedCategory == cat;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
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
                              child: Text(cat,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: sel
                                        ? const Color(0xFF1D9E75)
                                        : const Color(0xFF5A8A76),
                                  )),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _save,
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
                              : Text(
                                  _isEditing ? 'Save Changes' : 'Add Activity',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFFC8E8D8)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF3A5A4A), fontSize: 13),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: const Color(0xFF3A6A55), size: 18)
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
            borderSide:
                const BorderSide(color: Color(0xFF1D9E75), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF7A1F1F))),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }

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
          child: Icon(icon, color: const Color(0xFF5A8A76), size: 18),
        ),
      );
}