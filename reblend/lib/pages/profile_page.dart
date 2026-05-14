import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/recipe_service.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Get the current user's ID
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final RecipeService _recipeService = RecipeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    // AuthGate will see the logout and automatically switch to the LoginPage
  }

  @override
  Widget build(BuildContext context) {
    // If no user is logged in, show a simple error
    if (userId.isEmpty)
      return const Scaffold(body: Center(child: Text("No user found")));

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
                      _statBox(
                        "Rating",
                        (userData['avg_rating'] ?? 0.0).toString(),
                      ),
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
                      _buildPlaceholder("Your Twists List"),
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
      // Fetch all recipes from your service
      future: _recipeService.getAllRecipes(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF8FA67A)));
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error loading recipes: ${snapshot.error}"));
        }

        // Filter recipes to only show those belonging to the current user
        // and ensuring they aren't "twists" (if you want only original recipes here)
        final myRecipes = snapshot.data?.where((r) => r.userId == userId && !r.hasTwist).toList() ?? [];

        if (myRecipes.isEmpty) {
          return const Center(
            child: Text("You haven't posted any recipes yet.", 
            style: TextStyle(color: Colors.grey))
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailPage(recipe: recipe),
                    ),
                  );
                },
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
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
        ),
        onPressed: _handleLogout,
        child: const Text("Log Out"),
      ),
    );
  }
}
