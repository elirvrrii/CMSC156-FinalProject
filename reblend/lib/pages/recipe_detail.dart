import 'package:flutter/material.dart';
import '../models/recipe.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EC),
      body: CustomScrollView(
        slivers: [
          // Top bar
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20, color: Color(0xFF4A4A4A)),
                    ),
                    Column(
                      children: [
                        Text(
                          recipe.name,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                        Text(
                          '@${recipe.author}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8FA67A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.more_horiz, size: 22, color: Color(0xFF4A4A4A)),
                  ],
                ),
              ),
            ),
          ),

          // Hero image
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  recipe.imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: const Color(0xFFE8E0D8),
                    child: const Icon(Icons.image_outlined,
                        size: 48, color: Color(0xFFADADAD)),
                  ),
                ),
              ),
            ),
          ),

          // Tab bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE5DE),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    _TabChip(label: 'Ingredients', index: 0, selected: _selectedTab,
                        onTap: () => _tabController.animateTo(0)),
                    _TabChip(label: 'Procedure', index: 1, selected: _selectedTab,
                        onTap: () => _tabController.animateTo(1)),
                    _TabChip(label: 'Ratings', index: 2, selected: _selectedTab,
                        onTap: () => _tabController.animateTo(2)),
                  ],
                ),
              ),
            ),
          ),

          // Tab content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _selectedTab == 0
                    ? _IngredientsTab(key: const ValueKey(0), ingredients: recipe.ingredients)
                    : _selectedTab == 1
                        ? _ProcedureTab(key: const ValueKey(1), steps: recipe.steps)
                        : _RatingsTab(key: const ValueKey(2), reviews: recipe.reviews),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final int index;
  final int selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8FA67A) : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF888888),
            ),
          ),
        ),
      ),
    );
  }
}

class _IngredientsTab extends StatelessWidget {
  final List<String> ingredients;
  const _IngredientsTab({super.key, required this.ingredients});

  @override
  Widget build(BuildContext context) {
    // Grid of ingredient chips
    final rows = <Widget>[];
    for (int i = 0; i < ingredients.length; i += 4) {
      final rowItems = ingredients.skip(i).take(4).toList();
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: rowItems.asMap().entries.map((e) {
              final isHighlighted = e.key % 2 == 0 && i == 0;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: e.key < rowItems.length - 1 ? 8 : 0),
                  child: _IngredientChip(
                    label: e.value,
                    highlighted: isHighlighted,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

class _IngredientChip extends StatelessWidget {
  final String label;
  final bool highlighted;
  const _IngredientChip({required this.label, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFF8FA67A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? const Color(0xFF8FA67A) : const Color(0xFFDDD8D0),
          width: 1,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: highlighted ? Colors.white : const Color(0xFF4A4A4A),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ProcedureTab extends StatelessWidget {
  final List<String> steps;
  const _ProcedureTab({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps.asMap().entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAE5DE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8FA67A),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${e.key + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4A4A4A),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RatingsTab extends StatelessWidget {
  final List<RecipeReview> reviews;
  const _RatingsTab({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: reviews.map((review) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAE5DE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '@${review.author}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8FA67A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < review.rating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: const Color(0xFFE8A838),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  review.comment,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}