import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../emergency/presentation/pages/emergency_card_screen.dart';
import '../../../health_profile/presentation/widgets/health_profile_completeness_card.dart';
import '../../../interactions/presentation/pages/medicine_safety_screen.dart';
import '../../../interactions/presentation/widgets/medicine_safety_banner.dart';
import '../../../triage/presentation/pages/symptom_check_screen.dart';
import '../widgets/today_routine_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onSelectTab});

  /// Switches the parent [MainShell] tab. Indices:
  /// 0 Home, 1 Reports, 2 Routine, 3 Progress, 4 Profile.
  final ValueChanged<int>? onSelectTab;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        automaticallyImplyLeading: false,
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Your account data is unavailable.\n'
                  'If you just deleted your TARU account, sign out and sign in '
                  'again only if you create a new account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
              ),
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

                const SizedBox(height: 20),

                const HealthProfileCompletenessCard(),

                const SizedBox(height: 15),

                TodayRoutineCard(
                  onOpenRoutine: () => widget.onSelectTab?.call(2),
                ),

                const SizedBox(height: 15),

                const MedicineSafetyBanner(),

                _buildSymptomCheckButton(),

                const SizedBox(height: 12),

                _buildEmergencyCardButton(),

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
                        icon: Icons.description_outlined,
                        title: 'Reports',
                        onTap: () => widget.onSelectTab?.call(1),
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.calendar_today_outlined,
                        title: 'Routine',
                        onTap: () => widget.onSelectTab?.call(2),
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
                        title: 'Progress',
                        onTap: () => widget.onSelectTab?.call(3),
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.rule_outlined,
                        title: 'Medicine safety',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const MedicineSafetyScreen(),
                          ),
                        ),
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

  Widget _buildSymptomCheckButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SymptomCheckScreen()),
        ),
        icon: const Icon(Icons.health_and_safety_outlined),
        label: const Text(
          'Check a symptom',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Kept directly on Home rather than buried in the profile, because the one
  /// moment it matters is the moment nobody can go looking for it.
  Widget _buildEmergencyCardButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xffB3261E),
          side: const BorderSide(color: Color(0xffB3261E)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const EmergencyCardScreen()),
        ),
        icon: const Icon(Icons.emergency_outlined),
        label: const Text(
          'Emergency card',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
