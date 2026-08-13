import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/reliability/user_facing_error.dart';
import '../../application/auth_providers.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_textfield.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  bool hidePassword = true;

  bool isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await ref.read(authServiceProvider).login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // No navigation here: AuthGate listens to the auth state and swaps this
      // screen for the app shell as soon as the sign-in lands.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingErrorMessage(e))));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(e))),
      );
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
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const SizedBox(height: 40),

                const AuthHeader(
                  title: 'Welcome Back',
                  subtitle: 'Sign in to your TARU health organizer.',
                ),

                const SizedBox(height: 40),

                AuthTextField(
                  hintText: AppStrings.email,
                  icon: Icons.email_outlined,
                  controller: emailController,
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: passwordController,

                  obscureText: hidePassword,

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }

                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },

                  decoration: InputDecoration(
                    hintText: AppStrings.password,

                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.blue,
                    ),

                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword ? Icons.visibility_off : Icons.visibility,
                      ),

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

                Align(
                  alignment: Alignment.centerRight,

                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForgotPasswordScreen(
                            initialEmail: emailController.text.trim(),
                          ),
                        ),
                      );
                    },

                    child: const Text('Forgot Password?'),
                  ),
                ),

                const SizedBox(height: 10),

                AuthButton(
                  text: isLoading ? 'Logging in...' : AppStrings.login,

                  onPressed: isLoading ? null : loginUser,
                ),

                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },

                    child: const Text("Don't have an account? Sign Up"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
