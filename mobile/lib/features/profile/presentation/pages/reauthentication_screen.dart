import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/reliability/user_facing_error.dart';

class ReauthenticationScreen extends StatefulWidget {
  final String action;

  const ReauthenticationScreen({super.key, required this.action});

  @override
  State<ReauthenticationScreen> createState() => _ReauthenticationScreenState();
}

class _ReauthenticationScreenState extends State<ReauthenticationScreen> {
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  Future<void> reauthenticate() async {
    final String password = passwordController.text.trim();

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your current password.')),
      );
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authenticated user found.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      if (!mounted) return;

      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      appBar: AppBar(
        title: const Text('Security Verification'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 30),

              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.blue,
                    size: 55,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Center(
                child: Text(
                  'Verify Your Identity',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: Text(
                  'For your security, please enter your current password before you ${widget.action}.',
                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ),

              const SizedBox(height: 40),

              TextFormField(
                controller: passwordController,
                obscureText: hidePassword,

                decoration: InputDecoration(
                  labelText: 'Current password',

                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.blue,
                  ),

                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    tooltip: hidePassword ? 'Show password' : 'Hide password',
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 55),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : reauthenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isLoading ? 'Verifying…' : 'Verify Identity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  'Your password is never stored.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
