import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data (replace with real backend later)
  final int totalRecipes = 12;
  final int totalTwists = 5;
  final double avgRating = 4.8;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EC),
      body: SafeArea(
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

            const Text(
              "Your Name",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              "@username",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 16),

            // ─── Stats Row ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statBox("Recipes", totalRecipes.toString()),
                  _statBox("Twists", totalTwists.toString()),
                  _statBox("Rating", avgRating.toString()),
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
                  _buildPlaceholder("Your Recipes List"),
                  _buildPlaceholder("Your Twists List"),
                  _buildSettings(),
                  _buildLogout(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stats Widget ─────────────────────────────
  Widget _statBox(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  // ─── Placeholder Sections ─────────────────────────────
  Widget _buildPlaceholder(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey),
      ),
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
        ListTile(
          leading: Icon(Icons.lock_outline),
          title: Text("Privacy"),
        ),
        ListTile(
          leading: Icon(Icons.palette_outlined),
          title: Text("Theme"),
        ),
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
        onPressed: () {
          // Replace with auth logout later
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        child: const Text("Log Out"),
      ),
    );
  }
}