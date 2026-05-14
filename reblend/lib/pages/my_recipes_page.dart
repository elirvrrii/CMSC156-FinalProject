import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Recipes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8FAF6E)),
        useMaterial3: true,
        fontFamily: 'Georgia',
      ),
      home: const MyRecipesScreen(),
    );
  }
}

// ─── Data Models ───────────────────────────────────────────────────────────────

class Recipe {
  final String title;
  final String author;
  final double rating;
  final int reviewCount;
  final String date;
  final String imageUrl;
  final bool isTwist;

  const Recipe({
    required this.title,
    required this.author,
    required this.rating,
    required this.reviewCount,
    required this.date,
    required this.imageUrl,
    this.isTwist = false,
  });
}

// ─── Sample Data ───────────────────────────────────────────────────────────────

final List<Recipe> allRecipes = [
  const Recipe(
    title: 'Pasta Primavera',
    author: '@user',
    rating: 5.0,
    reviewCount: 130,
    date: '01/01/2026',
    imageUrl: 'https://images.unsplash.com/photo-1555949258-eb67b1ef0ceb?w=400',
    isTwist: false,
  ),
  const Recipe(
    title: 'Creamy Carbonara',
    author: '@user',
    rating: 4.8,
    reviewCount: 98,
    date: '02/15/2026',
    imageUrl: 'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=400',
    isTwist: false,
  ),
  const Recipe(
    title: 'Garlic Shrimp Pasta',
    author: '@user',
    rating: 4.9,
    reviewCount: 75,
    date: '03/10/2026',
    imageUrl: 'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=400',
    isTwist: false,
  ),
  const Recipe(
    title: 'Spicy Arrabbiata',
    author: '@user',
    rating: 4.7,
    reviewCount: 60,
    date: '03/22/2026',
    imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=400',
    isTwist: false,
  ),
  const Recipe(
    title: 'Pasta + Avocado Twist',
    author: '@user',
    rating: 4.6,
    reviewCount: 44,
    date: '02/01/2026',
    imageUrl: 'https://images.unsplash.com/photo-1529059997568-3d847b1154f0?w=400',
    isTwist: true,
  ),
  const Recipe(
    title: 'Korean Fusion Noodles',
    author: '@user',
    rating: 4.9,
    reviewCount: 112,
    date: '03/05/2026',
    imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
    isTwist: true,
  ),
  const Recipe(
    title: 'Truffle Mac & Cheese',
    author: '@user',
    rating: 5.0,
    reviewCount: 88,
    date: '01/20/2026',
    imageUrl: 'https://images.unsplash.com/photo-1543339308-43e59d6b73a6?w=400',
    isTwist: true,
  ),
  const Recipe(
    title: 'Miso Butter Ramen',
    author: '@user',
    rating: 4.8,
    reviewCount: 55,
    date: '03/30/2026',
    imageUrl: 'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=400',
    isTwist: true,
  ),
];

// ─── Main Screen ───────────────────────────────────────────────────────────────

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  int _selectedCategoryIndex = 0;

  static const Color _accentGreen = Color(0xFF8FAF6E);
  static const Color _lightBg = Color(0xFFF5F0E8);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF2C2C2C);
  static const Color _textMuted = Color(0xFF9E9E9E);

  final List<String> _categories = ['My Recipes', 'My Twists'];

  List<Recipe> get _filteredRecipes {
    if (_selectedCategoryIndex == 0) {
      return allRecipes.where((r) => !r.isTwist).toList();
    } else {
      return allRecipes.where((r) => r.isTwist).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),

    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            color: _textDark,
            onPressed: () {},
          ),
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
            icon: const Icon(Icons.logout_rounded),
            color: _textDark,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ─── Search Bar ───────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded, color: _textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for your preferred recipe',
                  hintStyle: const TextStyle(
                    color: _textMuted,
                    fontSize: 14,
                    fontFamily: 'Georgia',
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategorySection(),
        Expanded(child: _buildRecipeGrid()),
      ],
    );
  }

  // ─── Categories ───────────────────────────────────────────────────────────

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textDark,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 10),
          Row(
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
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
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
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ─── Recipe Grid ──────────────────────────────────────────────────────────

  Widget _buildRecipeGrid() {
    final recipes = _filteredRecipes;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) => _buildRecipeCard(recipes[index]),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  recipe.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFE8E0D0),
                    child: const Icon(Icons.restaurant_menu,
                        color: _textMuted, size: 40),
                  ),
                ),
                if (recipe.isTwist)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _accentGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Twist',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                        fontFamily: 'Georgia',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        recipe.author,
                        style: const TextStyle(
                          fontSize: 10,
                          color: _textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_border_rounded,
                        size: 14, color: _textMuted),
                    const SizedBox(width: 2),
                    Text(
                      '${recipe.rating} (${recipe.reviewCount}+)',
                      style: const TextStyle(
                          fontSize: 11, color: _textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  recipe.date,
                  style: const TextStyle(fontSize: 10, color: _textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}