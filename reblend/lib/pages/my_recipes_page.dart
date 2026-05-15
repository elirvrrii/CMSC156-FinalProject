import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../widgets/recipe_card.dart';
import 'add_recipe_page.dart';
import 'login_page.dart';
import 'recipe_detail.dart';

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  final RecipeService _recipeService = RecipeService();
  final TextEditingController _searchController = TextEditingController();

  StreamSubscription<User?>? _authSubscription;
  Future<List<Recipe>>? _recipesFuture;
  User? _currentUser;
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';

  static const Color _accentGreen = Color(0xFF8FAF6E);
  static const Color _lightBg = Color(0xFFF5F0E8);
  static const Color _textDark = Color(0xFF2C2C2C);
  static const Color _textMuted = Color(0xFF9E9E9E);

  final List<String> _categories = const ['My Recipes', 'My Twists'];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _recipesFuture = _loadMyRecipes();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) {
        return;
      }
      setState(() {
        _currentUser = user;
        _recipesFuture = _loadMyRecipes();
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Recipe>> _loadMyRecipes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const [];
    }
    return _recipeService.getRecipesByUserId(user.uid);
  }

  List<Recipe> _filterRecipes(List<Recipe> recipes) {
    final visibleRecipes = _selectedCategoryIndex == 0
        ? recipes.where((recipe) => !recipe.hasTwist)
        : recipes.where((recipe) => recipe.hasTwist);

    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return visibleRecipes.toList();
    }

    return visibleRecipes
        .where((recipe) =>
            recipe.name.toLowerCase().contains(query) ||
            recipe.category.toLowerCase().contains(query))
        .toList();
  }

  void _openRecipe(Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecipeDetailPage(recipe: recipe),
      ),
    );
  }

Future<void> _refresh() async {
  setState(() {
    _recipesFuture = _loadMyRecipes();
  });
  await _recipesFuture;
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recipes refreshed'),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF8FA67A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: _lightBg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 56, color: _accentGreen),
                  const SizedBox(height: 16),
                  const Text(
                    'Sign in to view your recipes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Recipes you add are linked to your account automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _textMuted),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Login / Register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategorySection(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: FutureBuilder<List<Recipe>>(
                  future: _recipesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return ListView(
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Text(
                              'Failed to load your recipes',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: ElevatedButton(
                              onPressed: _refresh,
                              child: const Text('Retry'),
                            ),
                          ),
                        ],
                      );
                    }

                    final recipes = _filterRecipes(snapshot.data ?? const []);

                    if (recipes.isEmpty) {
                      return ListView(
                        children: [
                          const SizedBox(height: 120),
                          const Icon(Icons.menu_book_outlined, size: 56, color: _accentGreen),
                          const SizedBox(height: 12),
                          const Text(
                            'No recipes yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add a recipe and it will appear here under your account.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _textMuted),
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => AddRecipePage.show(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Recipe'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentGreen,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                      itemCount: recipes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        return RecipeCard(
                          recipe: recipes[index],
                          isOwner: true,
                          onTap: () => _openRecipe(recipes[index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentGreen,
        foregroundColor: Colors.white,
        onPressed: () => AddRecipePage.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          const Icon(Icons.person_outline_rounded, color: _textDark),
          const Spacer(),
          const Text(
            'My Recipes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: _textDark,
              fontFamily: 'Georgia',
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: _textDark,
            onPressed: _refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: const InputDecoration(
            hintText: 'Search your recipes',
            hintStyle: TextStyle(
              color: _textMuted,
              fontSize: 14,
              fontFamily: 'Georgia',
            ),
            prefixIcon: Icon(Icons.search_rounded, color: _textMuted, size: 20),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: List.generate(_categories.length, (index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                children: [
                  Text(
                    _categories[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? _accentGreen : _textMuted,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isSelected)
                    Container(
                      height: 2,
                      width: 60,
                      decoration: BoxDecoration(
                        color: _accentGreen,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}