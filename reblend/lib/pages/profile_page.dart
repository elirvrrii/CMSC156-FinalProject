import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'main_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String userId =
      FirebaseAuth.instance.currentUser?.uid ?? "";

  final User? currentUser =
      FirebaseAuth.instance.currentUser;

  // ───────────────── LOGOUT ─────────────────
  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
        (route) => false,
      );
    }
  }

  // ───────────────── LOGOUT DIALOG ─────────────────
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  "Logout?",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Are you sure you want to logout from your account?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFC97C39),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _handleLogout,
                        child: const Text("Yes, Logout"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────── EDIT PROFILE ─────────────────
  Future<void> _editProfile(
    String currentName,
  ) async {
    final controller = TextEditingController(
      text: currentName,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Profile"),

          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: "Display Name",
              border: OutlineInputBorder(),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                final newName =
                    controller.text.trim();

                if (newName.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({
                  'display_name': newName,
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content:
                        Text("Profile updated"),
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // ───────────────── CHANGE PASSWORD ─────────────────
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Change Password",
          ),

          content: const Text(
            "A password reset link will be sent to your email.",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                if (currentUser?.email == null) {
                  return;
                }

                try {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(
                    email: currentUser!.email!,
                  );

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Password reset email sent",
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString(),
                      ),
                    ),
                  );
                }
              },
              child: const Text("Continue"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text("No user found"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EC),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF5F1EC),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF5C5346),
          ),
        ),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text("Profile not found"),
            );
          }

          final userData =
              snapshot.data!.data()
                  as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // PROFILE CARD
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 42,
                        backgroundColor:
                            Color(0xFF8FA67A),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData[
                                      'display_name'] ??
                                  'Chef',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              userData['email'] ?? '',
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              'Loves cooking and sharing recipes!',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // STATS
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                    children: [
                      _statItem(
                        Icons.restaurant,
                        'Recipes',
                        (userData['recipe_count'] ??
                                0)
                            .toString(),
                      ),

                      _statItem(
                        Icons.auto_awesome,
                        'Twists',
                        (userData['twist_count'] ??
                                0)
                            .toString(),
                      ),

                      _statItem(
                        Icons.star,
                        'Ratings',
                        (userData['avg_rating'] ??
                                0)
                            .toString(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // MENU CARD
                _menuCard([
                  _menuTile(
                    icon: Icons.edit,
                    title: 'Edit Profile',
                    onTap: () {
                      _editProfile(
                        userData['display_name'] ??
                            'Chef',
                      );
                    },
                  ),

                  _menuTile(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    onTap:
                        _showChangePasswordDialog,
                  ),
                ]),

                const SizedBox(height: 24),

                // LOGOUT
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.red.shade50,
                      foregroundColor:
                          Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                                18),
                      ),
                    ),
                    onPressed:
                        _showLogoutDialog,
                    icon:
                        const Icon(Icons.logout),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // ───────────────── STATS ITEM ─────────────────
  Widget _statItem(
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF8FA67A),
          size: 28,
        ),

        const SizedBox(height: 10),

        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // ───────────────── MENU CARD ─────────────────
  Widget _menuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ───────────────── MENU TILE ─────────────────
  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF8FA67A),
      ),
      title: Text(title),
      trailing:
          const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}