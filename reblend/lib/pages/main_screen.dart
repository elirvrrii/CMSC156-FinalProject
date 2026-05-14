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
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    MyRecipesScreen(),
    Center(child: Text("Add Recipe")),
    ValidateTwistsPage(),
    ProfilePage(),
  ];

  void _onTap(int index) {
    if (index == 2) {
      AddRecipePage.show(context);
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}