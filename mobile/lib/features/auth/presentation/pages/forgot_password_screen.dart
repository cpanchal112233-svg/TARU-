import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/auth_providers.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_textfield.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  static bool _looksLikeEmail(String value) {
    final String email = value.trim();
    if (email.isEmpty) return false;
    final int at = email.indexOf('@');
    if (at <= 0 || at != email.lastIndexOf('@')) return false;
    final String domain = email.substring(at + 1);
    return domain.contains('.') &&
        !domain.startsWith('.') &&
        !domain.endsWith('.');
  }

  Future<void> _sendReset() async {
    if (_isLoading) return;
    setState(() {
      _error = null;
      _sent = false;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .sendPasswordResetEmail(_emailController.text);
      if (!mounted) return;
      setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Do not confirm whether the account exists.
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        setState(() => _sent = true);
        return;
      }
      setState(() => _error = _messageFor(e.code));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static String _messageFor(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Could not send reset instructions. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter your registered email address and we will send '
                  'password reset instructions if an account exists.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 40),
                AuthTextField(
                  labelText: 'Email address',
                  hintText: 'Email',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_isLoading) {
                      _sendReset();
                    }
                  },
                  validator: (String? value) {
                    final String email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Please enter your email.';
                    if (!_looksLikeEmail(email)) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xffB3261E)),
                  ),
                ],
                if (_sent) ...[
                  const SizedBox(height: 16),
                  Text(
                    'If an account exists for that email, we have sent password '
                    'reset instructions. Check your inbox and spam folder.',
                    style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                  ),
                ],
                const SizedBox(height: 30),
                AuthButton(
                  text: _isLoading
                      ? 'Sending reset instructions'
                      : 'Send Reset Link',
                  busy: _isLoading,
                  onPressed: _isLoading ? null : _sendReset,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
