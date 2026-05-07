import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../widgets/navbar.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  int _selectedCategory = 0;

  final List<String> _categories = ['main dish', 'side dish', 'appetizer', 'dessert'];

  void _openRecipe(Recipe recipe) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => RecipeDetailPage(recipe: recipe),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EC),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.notifications_none_rounded,
                      size: 24, color: Color(0xFF4A4A4A)),
                  Column(
                    children: const [
                      Text(
                        'App Name',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E2E2E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'subtitle.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8FA67A),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.logout_rounded,
                      size: 22, color: Color(0xFF4A4A4A)),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    SizedBox(width: 14),
                    Icon(Icons.search_rounded, color: Color(0xFFADADAD), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search for your preferred recipe',
                        style: TextStyle(
                          color: Color(0xFFBBBBBB),
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Categories
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _categories.asMap().entries.map((e) {
                      final isSelected = e.key == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 18),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = e.key),
                          child: Column(
                            children: [
                              Text(
                                e.value,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? const Color(0xFF8FA67A)
                                      : const Color(0xFF888888),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  height: 2,
                                  width: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8FA67A),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Recipe list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                itemCount: sampleRecipes.length,
                itemBuilder: (context, index) {
                  return RecipeCard(
                    recipe: sampleRecipes[index],
                    onTap: () => _openRecipe(sampleRecipes[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}