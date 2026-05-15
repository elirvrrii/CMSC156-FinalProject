import 'package:firebase_auth/firebase_auth.dart';
import 'package:reblend/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:reblend/pages/profile_page.dart';
import '../widgets/navbar.dart';
import 'home_screen.dart';
import 'my_recipes_page.dart';
import 'add_recipe_page.dart';
import 'validate_twists.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Helper to check login status
  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  void _onTap(int index) {
    // Always allow Home (index 0)
    if (index == 0) {
      setState(() => _currentIndex = index);
      return;
    }

    // For all other tabs, check if the user is logged in
    if (!_isLoggedIn) {
      showLoginRequiredDialog();
      return;
    }

    // If logged in, handle the 'Add' button (index 2)
    if (index == 2) {
      AddRecipePage.show(context);
      return;
    }

    // Otherwise, just change the tab
    setState(() {
      _currentIndex = index;
    });
  }

  // Popup dialog box
  void showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Join the Kitchen!"),
        content: const Text(
          "You need an account to create recipes, view your profile, and validate twists.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8FA67A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text("Login / Register"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = const [
      HomeScreen(),
      MyRecipesScreen(),
      AddRecipePage(),
      ValidateTwistsPage(),
      ProfilePage(),
    ];

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
