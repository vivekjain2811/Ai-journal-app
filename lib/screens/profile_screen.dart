import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../services/journal_service.dart'; // Add import
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final UserService userService = UserService();

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<UserModel?>(
        stream: user != null ? userService.getUserProfile(user.uid) : const Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data;
          
          // Fallback values if data is missing or user just signed up and has no profile doc yet
          final String displayName = userData?.username?.isNotEmpty == true 
              ? userData!.username! 
              : (user?.displayName ?? 'User Name');
          final String email = userData?.email ?? user?.email ?? 'No Email';
          final String? photoUrl = userData?.photoUrl ?? user?.photoURL;
          final String motto = userData?.motto ?? 'Driven by purpose.'; // Default motto

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: photoUrl != null 
                      ? NetworkImage(photoUrl) 
                      : null,
                  child: photoUrl == null
                      ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                      : null,
                ),
                const SizedBox(height: 16),
                
                // Name & Email
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                
                // Motto
                if (motto.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '"$motto"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                
                // Stats Row (Mock data for now or real if implementing count)
                // Stats Row
                StreamBuilder<Map<String, dynamic>>(
                  stream: JournalService().getJournalStats(user?.uid ?? ''),
                  builder: (context, statsSnapshot) {
                    String entriesCount = '-';
                    String streakCount = '-';

                    if (statsSnapshot.hasData) {
                      entriesCount = statsSnapshot.data!['totalEntries'].toString();
                      streakCount = '${statsSnapshot.data!['currentStreak']} 🔥';
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(context, 'Total Entries', entriesCount),
                        _buildStatCard(context, 'Day Streak', streakCount),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                
                // Details Section (Phone, etc.)
                if (userData?.phoneNumber != null && userData!.phoneNumber!.isNotEmpty)
                   _buildInfoTile(context, Icons.phone, userData.phoneNumber!),

                const SizedBox(height: 32),

                // Edit Button
                PrimaryButton(
                  text: 'Edit Profile',
                  isOutlined: true,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(user: userData),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
