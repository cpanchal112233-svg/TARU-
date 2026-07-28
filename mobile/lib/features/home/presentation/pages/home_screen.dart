import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../profile/presentation/pages/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> createMissingUserProfile(User user) async {
    final userDocument = _firestore.collection('users').doc(user.uid);

    final snapshot = await userDocument.get();

    if (!snapshot.exists) {
      await userDocument.set({
        'name': user.displayName ?? 'User',
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('No user is currently logged in.')),
      );
    }

    final String uid = currentUser.uid;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      appBar: AppBar(
        title: const Text('TARU'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,

        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('users').doc(uid).snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading profile:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return FutureBuilder(
              future: createMissingUserProfile(currentUser),

              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (profileSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not create user profile:\n'
                      '${profileSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            );
          }

          final Map<String, dynamic> data = snapshot.data!.data() ?? {};

          final String name = data['name']?.toString() ?? 'User';

          final String email =
              data['email']?.toString() ?? currentUser.email ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const SizedBox(height: 20),

                Text(
                  'Welcome back,',
                  style: TextStyle(fontSize: 20, color: Colors.grey.shade700),
                ),

                const SizedBox(height: 5),

                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(email, style: TextStyle(color: Colors.grey.shade600)),

                const SizedBox(height: 35),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(24),
                  ),

                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Icon(Icons.favorite, color: Colors.white, size: 40),

                      SizedBox(height: 15),

                      Text(
                        'Your Health Journey Starts Here',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        'TARU is here to help you understand '
                        'and improve your health.',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.chat_bubble_outline,
                        title: 'AI Assistant',
                        onTap: () {},
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.monitor_heart_outlined,
                        title: 'Health Data',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.insights_outlined,
                        title: 'Insights',
                        onTap: () {},
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.person_outline,
                        title: 'Profile',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
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

        child: Column(
          children: [
            Icon(icon, size: 35, color: Colors.blue),

            const SizedBox(height: 12),

            Text(
              title,
              textAlign: TextAlign.center,

              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
