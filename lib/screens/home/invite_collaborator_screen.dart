import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InviteCollaboratorScreen extends StatefulWidget {
  final String tripId;
  const InviteCollaboratorScreen({super.key, required this.tripId});

  @override
  State<InviteCollaboratorScreen> createState() =>
      _InviteCollaboratorScreenState();
}

class _InviteCollaboratorScreenState
    extends State<InviteCollaboratorScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(() { _message = 'Enter a valid email.'; _isError = true; });
      return;
    }

    setState(() { _isLoading = true; _message = null; });

    try {
      // Look up user by email
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() {
          _message = 'No account found with that email.';
          _isError = true;
        });
        return;
      }

      final inviteeUid = query.docs.first.id;

      // Check if already a collaborator
      final tripDoc = await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .get();
      final collabs =
          List<String>.from(tripDoc['collaborators'] ?? []);

      if (collabs.contains(inviteeUid)) {
        setState(() {
          _message = 'That person is already on this trip.';
          _isError = true;
        });
        return;
      }

      // Add to collaborators
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .update({
        'collaborators': FieldValue.arrayUnion([inviteeUid]),
      });

      setState(() {
        _message = 'Collaborator added successfully!';
        _isError = false;
        _emailController.clear();
      });
    } catch (e) {
      setState(() {
        _message = 'Something went wrong. Try again.';
        _isError = true;
      });
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                const Text('Invite Collaborator',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE8F5EF))),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your travel partner\'s email address. They must already have a TropicaGuide account.',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4D7A6A),
                        height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  const Text('EMAIL ADDRESS',
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF5A8A76),
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),

                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFFC8E8D8)),
                        decoration: InputDecoration(
                          hintText: 'partner@email.com',
                          hintStyle: const TextStyle(
                              color: Color(0xFF3A5A4A), fontSize: 13),
                          prefixIcon: const Icon(Icons.mail_outline_rounded,
                              color: Color(0xFF3A6A55), size: 18),
                          filled: true,
                          fillColor: const Color(0xFF0F2820),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1E3D2E))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1E3D2E))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1D9E75), width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _isLoading ? null : _invite,
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1D9E75), Color(0xFF0D6B52)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.person_add_rounded,
                                color: Colors.white, size: 20),
                      ),
                    ),
                  ]),

                  if (_message != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isError
                            ? const Color(0xFF3B0E0E)
                            : const Color(0xFF0D2518),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isError
                              ? const Color(0xFF7A1F1F)
                              : const Color(0xFF1D9E75),
                        ),
                      ),
                      child: Text(_message!,
                          style: TextStyle(
                            fontSize: 13,
                            color: _isError
                                ? const Color(0xFFFFB4B4)
                                : const Color(0xFF9AC8B4),
                          )),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}