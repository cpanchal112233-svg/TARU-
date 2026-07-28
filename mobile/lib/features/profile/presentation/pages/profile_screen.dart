import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../auth/data/auth_service.dart';
import 'reauthentication_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  bool isChangingName = false;
  bool isChangingPassword = false;
  bool isChangingEmail = false;
  bool isChangingPhone = false;

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      // AuthGate reacts to the signed-out state and shows the login screen.
      await _authService.logout();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not log out.')),
      );
    }
  }

  Future<bool> verifyIdentity(String action) async {
    final bool? verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ReauthenticationScreen(action: action)),
    );

    return verified ?? false;
  }
  // ============================================================
  // EDIT NAME
  // ============================================================

  Future<void> editName(String currentName) async {
    final bool verified = await verifyIdentity('change your name');

    if (!mounted) return;

    if (!verified) {
      return;
    }
    final TextEditingController nameController = TextEditingController(
      text: currentName,
    );

    final String? newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Name'),

          content: TextField(
            controller: nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Enter your name'),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                final String name = nameController.text.trim();

                if (name.isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext, name);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();

    if (newName == null || newName.isEmpty) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      isChangingName = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'name': newName},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully!')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not update your name.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isChangingName = false;
        });
      }
    }
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<void> changePassword() async {
    final bool verified = await verifyIdentity('change your password');

    if (!verified) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      return;
    }

    if (!mounted) return;

    setState(() {
      isChangingPassword = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Please check your inbox.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Could not send password reset email.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isChangingPassword = false;
        });
      }
    }
  }

  // ============================================================
  // CHANGE EMAIL
  // ============================================================

  Future<void> changeEmail(String currentEmail) async {
    final bool verified = await verifyIdentity('change your email');

    if (!mounted) return;

    if (!verified) {
      return;
    }

    final TextEditingController emailController = TextEditingController(
      text: currentEmail,
    );

    final String? newEmail = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Email'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Enter your new email'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, emailController.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    emailController.dispose();

    if (newEmail == null || newEmail.isEmpty) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    if (!mounted) return;

    setState(() {
      isChangingEmail = true;
    });

    try {
      await user.verifyBeforeUpdateEmail(newEmail);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'email': newEmail},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification email sent. Please verify your new email address.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not change email.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isChangingEmail = false;
        });
      }
    }
  }

  Future<void> changePhoneNumber() async {
    final bool verified = await verifyIdentity('change your phone number');

    if (!mounted) return;

    if (!verified) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone verification will be implemented next.'),
      ),
    );
  }
  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user is currently logged in.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User profile not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final String name = data['name'] ?? 'User';

          final String email = data['email'] ?? user.email ?? '';

          final String phone = data['phone'] ?? 'No phone number added';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              children: [
                const SizedBox(height: 20),

                // PROFILE AVATAR
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.blue,

                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  email,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 35),

                // EDIT NAME
                _buildProfileOption(
                  icon: Icons.person_outline,
                  title: 'Edit Name',
                  subtitle: isChangingName
                      ? 'Updating...'
                      : 'Change your display name',

                  onTap: isChangingName ? () {} : () => editName(name),
                ),

                const SizedBox(height: 15),

                // CHANGE PASSWORD
                _buildProfileOption(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: isChangingPassword
                      ? 'Sending email...'
                      : 'Send a password reset email',

                  onTap: isChangingPassword ? () {} : changePassword,
                ),

                const SizedBox(height: 15),

                // CHANGE EMAIL
                _buildProfileOption(
                  icon: Icons.email_outlined,
                  title: 'Change Email',
                  subtitle: isChangingEmail
                      ? 'Processing...'
                      : 'Change your email address',

                  onTap: isChangingEmail ? () {} : () => changeEmail(email),
                ),

                const SizedBox(height: 15),

                // CHANGE PHONE NUMBER
                _buildProfileOption(
                  icon: Icons.phone_outlined,
                  title: 'Phone Number',
                  subtitle: phone,

                  onTap: isChangingPhone ? () {} : changePhoneNumber,
                ),

                const SizedBox(height: 15),

                // LOGOUT
                _buildProfileOption(
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out of your TARU account',
                  onTap: logout,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // PROFILE OPTION CARD
  // ============================================================

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(20),

      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),

              child: Icon(icon, color: Colors.blue, size: 28),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
