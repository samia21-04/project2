import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'user-not-found'  => 'No account found with this email.',
          'wrong-password'  => 'Incorrect password. Please try again.',
          'invalid-email'   => 'Please enter a valid email address.',
          'user-disabled'   => 'This account has been disabled.',
          _                 => 'Sign in failed. Please try again.',
        };
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
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0D2A1E), Color(0xFF0D1F18)],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Logo row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1D9E75), Color(0xFF0D6B52)],
                              ),
                            ),
                            child: const Icon(Icons.language_rounded,
                                color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 10),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFD4EDE3),
                              ),
                              children: [
                                TextSpan(text: 'Tropica'),
                                TextSpan(
                                  text: 'Guide',
                                  style: TextStyle(color: Color(0xFF1D9E75)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE8F5EF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sign in to your account',
                        style: TextStyle(fontSize: 13, color: Color(0xFF4D7A6A)),
                      ),
                    ],
                  ),
                ),

                // Form body
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error banner
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B0E0E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF7A1F1F)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFFFB4B4), fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildLabel('Email address'),
                      _buildTextField(
                        controller: _emailController,
                        hint: 'you@email.com',
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || !v.contains('@'))
                                ? 'Enter a valid email'
                                : null,
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Password'),
                      _buildTextField(
                        controller: _passwordController,
                        hint: 'Your password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF3A6A55),
                            size: 18,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter your password' : null,
                      ),
                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            // TODO: implement forgot password
                          },
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF1D9E75)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign in button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D9E75),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFF1D9E75).withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Sign In',
                                  style: TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Divider
                      Row(children: [
                        Expanded(
                            child: Divider(color: const Color(0xFF1A3028))),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or continue with',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF3A5A4A))),
                        ),
                        Expanded(
                            child: Divider(color: const Color(0xFF1A3028))),
                      ]),
                      const SizedBox(height: 16),

                      // Google sign-in placeholder
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: implement Google sign-in
                          },
                          icon: const Icon(Icons.g_mobiledata_rounded,
                              size: 20, color: Color(0xFF9AC8B4)),
                          label: const Text('Continue with Google',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF9AC8B4))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1E3D2E)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? ",
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF4D7A6A))),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/signup'),
                            child: const Text('Sign up',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1D9E75),
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF5A8A76),
          letterSpacing: 1.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFFC8E8D8)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFF3A5A4A), fontSize: 13),
        prefixIcon:
            Icon(prefixIcon, color: const Color(0xFF3A6A55), size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF0F2820),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3D2E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3D2E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7A1F1F)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}