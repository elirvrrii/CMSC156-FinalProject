import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/recipe_service.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail.dart';
import 'main_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Get the current user's ID
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final RecipeService _recipeService = RecipeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  String _formatRating(dynamic value) {
    if (value == null) return '—';
    final parsed = (value is num)
        ? value.toDouble()
        : double.tryParse(value.toString());
    if (parsed == null || parsed == 0.0) return '—';
    return parsed.toStringAsFixed(1);
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    // AuthGate will see the logout and automatically switch to the LoginPage
  }

  @override
  Widget build(BuildContext context) {
    // If no user is logged in, show a simple error
    if (userId.isEmpty) {
      return const Scaffold(body: Center(child: Text("No user found")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EC),
      body: StreamBuilder<DocumentSnapshot>(
        // Pointing to the specific user document
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Profile not found"));
          }

          // Extract the data safely
          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ─── Profile Header ─────────────────────────────
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFF8FA67A),
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),

                const SizedBox(height: 10),

                Text(
                  userData['display_name'] ?? "Chef",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  userData['email'] ?? "@username",
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 16),

                // ─── Stats Row ─────────────────────────────
                // ─── Stats Row ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statBox(
                        "Recipes",
                        (userData['recipe_count'] ?? 0).toString(),
                      ),
                      _statBox(
                        "Twists",
                        (userData['twist_count'] ?? 0).toString(),
                      ),
                      _statBox("Rating", _formatRating(userData['avg_rating'])),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Tabs ─────────────────────────────
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF8FA67A),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF8FA67A),
                  tabs: const [
                    Tab(text: "My Recipes"),
                    Tab(text: "My Twists"),
                    Tab(text: "Settings"),
                    Tab(text: "Logout"),
                  ],
                ),

                // ─── Tab Views ─────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMyRecipes(),
                      _buildMyTwists(),
                      _buildSettings(),
                      _buildLogout(context),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyRecipes() {
    return FutureBuilder<List<Recipe>>(
      future: _recipeService.getRecipesByUserId(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF8FA67A)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Error loading recipes: ${snapshot.error}"),
          );
        }

        final myRecipes =
            snapshot.data?.where((r) => !r.hasTwist).toList() ?? [];

        if (myRecipes.isEmpty) {
          return const Center(
            child: Text(
              "You haven't posted any recipes yet.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myRecipes.length,
          itemBuilder: (context, index) {
            final recipe = myRecipes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RecipeCard(
                recipe: recipe,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailPage(recipe: recipe),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyTwists() {
    return FutureBuilder<List<Recipe>>(
      future: _recipeService.getRecipesByUserId(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF8FA67A)),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading twists: ${snapshot.error}"));
        }

        final myTwists = snapshot.data?.where((r) => r.hasTwist).toList() ?? [];

        if (myTwists.isEmpty) {
          return const Center(
            child: Text(
              "You haven't posted any twists yet.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myTwists.length,
          itemBuilder: (context, index) {
            final recipe = myTwists[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RecipeCard(
                recipe: recipe,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailPage(recipe: recipe),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Stats Widget ─────────────────────────────
  Widget _statBox(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  // ─── Placeholder Sections ─────────────────────────────
  Widget _buildPlaceholder(String text) {
    return Center(
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }

  // ─── Settings Tab ─────────────────────────────
  Widget _buildSettings() {
    return ListView(
      children: const [
        ListTile(
          leading: Icon(Icons.person_outline),
          title: Text("Edit Profile"),
        ),
        ListTile(
          leading: Icon(Icons.notifications_none),
          title: Text("Notifications"),
        ),
        ListTile(leading: Icon(Icons.lock_outline), title: Text("Privacy")),
        ListTile(leading: Icon(Icons.palette_outlined), title: Text("Theme")),
      ],
    );
  }

  // ─── Logout Tab ─────────────────────────────
  Widget _buildLogout(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),

        // ─── Logout List Tile ─────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    "Log out?",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  content: const Text(
                    "You'll need to sign in again to access your recipes.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();

                        if (context.mounted) {
                          // This clears the navigation stack and sends them back to MainScreen.
                          // Because they are now "null" in Firebase, MainScreen will show the Guest view.
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const MainScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text(
                        "Log out",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) _handleLogout();
            },
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
            title: const Text(
              "Log Out",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2E2E2E),
              ),
            ),
            subtitle: const Text(
              "Sign out of your account",
              style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCCCCCC),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}
