import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import '../models/recipe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/recipe_service.dart';
import 'add_recipe_page.dart';

// ── Colour palette for diff states ────────────────────────────────────────

class _DiffColors {
  static const addedBg     = Color(0xFFE8F5E9);
  static const addedBorder = Color(0xFF8FA67A);
  static const addedText   = Color(0xFF4A7C59);

  static const removedBg     = Color(0xFFFFEBEE);
  static const removedBorder = Color(0xFFE57373);
  static const removedText   = Color(0xFFC62828);

  static const modifiedBg     = Color(0xFFFFF8E1);
  static const modifiedBorder = Color(0xFFFFB74D);
  static const modifiedText   = Color(0xFFE65100);

  static const unchangedBg     = Colors.white;
  static const unchangedBorder = Color(0xFFDDD8D0);
  static const unchangedText   = Color(0xFF4A4A4A);
}

// ── Detail page ────────────────────────────────────────────────────────────

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

  void _showDeleteConfirmation(BuildContext context, Recipe recipe) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recipe', style: TextStyle(color: Color(0xFF2E2E2E))),
        content: const Text('Are you sure you want to delete this recipe? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              Navigator.pop(ctx); // Close dialog
              try {
                // Call your delete service
                await RecipeService().deleteRecipe(recipe.id); 
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Recipe deleted successfully'),
                      backgroundColor: Color(0xFF8FA67A),
                    ),
                  );
                  navigator.pop(); // Exit the detail page
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: const Color(0xFFE57373),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
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
    final isTwist = recipe.parentRecipeId != null;
    // Check if current user is the owner
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    // Assuming your Recipe model has a 'userId' property. 
    // If it uses 'authorId' or similar, change this accordingly.
    final isOwner = currentUserUid != null && recipe.userId == currentUserUid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EC),
      body: CustomScrollView(
        slivers: [
          // ── Top bar ──────────────────────────────────────────────────────
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

                        if (recipe.parentRecipeId != null && recipe.parentRecipeName != null && recipe.parentRecipeAuthor != null)
  GestureDetector(
    onTap: () async {
  try {
    final parentRecipe = await RecipeService().getRecipeById(recipe.parentRecipeId!);
    if (parentRecipe == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Original recipe no longer exists'),
            backgroundColor: Color(0xFFE57373),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeDetailPage(recipe: parentRecipe),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load original recipe'),
          backgroundColor: Color(0xFFE57373),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
},
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.link_rounded,
          size: 11,
          color: Color(0xFFC8956C),
        ),
        const SizedBox(width: 3),
        Text(
          'orig. recipe by @${recipe.parentRecipeAuthor}',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFFC8956C),
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFFC8956C),
          ),
        ),
      ],
    ),
  ),
                      ],
                    ),

                  // Replace the existing more_horiz icon with this logic:
                  if (isOwner)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, size: 22, color: Color(0xFF4A4A4A)),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'edit') {
                          AddRecipePage.showEdit(context, recipe);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(context, recipe);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20, color: Color(0xFF8FA67A)),
                              SizedBox(width: 8),
                              Text('Edit Recipe'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20, color: Color(0xFFE57373)),
                              SizedBox(width: 8),
                              Text('Delete Recipe', style: TextStyle(color: Color(0xFFE57373))),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    const Icon(Icons.more_horiz, size: 22, color: Color(0xFF4A4A4A)),
                  ],
                ),
              ),
            ),
          ),

          // ── Hero image ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildRecipeImage(recipe.imageUrl),
              ),
            ),
          ),

          // ── Twist change summary (only for twists) ───────────────────────
          if (isTwist)
            SliverToBoxAdapter(
              child: _TwistChangeSummary(recipe: recipe),
            ),

          // ── Tab bar ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE5DE),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    _TabChip(
                        label: 'Ingredients',
                        index: 0,
                        selected: _selectedTab,
                        onTap: () => _tabController.animateTo(0)),
                    _TabChip(
                        label: 'Procedure',
                        index: 1,
                        selected: _selectedTab,
                        onTap: () => _tabController.animateTo(1)),
                    _TabChip(
                        label: 'Ratings',
                        index: 2,
                        selected: _selectedTab,
                        onTap: () => _tabController.animateTo(2)),
                  ],
                ),
              ),
            ),
          ),

          // ── Tab content ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _selectedTab == 0
                    ? _IngredientsTab(
                        key: const ValueKey(0),
                        ingredients: recipe.ingredients,
                        isTwist: isTwist,
                      )
                    : _selectedTab == 1
                        ? _ProcedureTab(
                            key: const ValueKey(1),
                            steps: recipe.steps,
                            isTwist: isTwist,
                          )
                        : _RatingsTab(
                            key: const ValueKey(2),
                            reviews: recipe.reviews,
                            averageRating: recipe.rating,
                            reviewCount: recipe.reviewCount,
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeImage(String imagePath) {
    // Check if it's a network URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imageErrorPlaceholder(),
      );
    }
    
    // Try to load as local file (native platforms only)
    if (!kIsWeb) {
      try {
        final file = io.File(imagePath);
        if (file.existsSync()) {
          return Image.file(
            file,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _imageErrorPlaceholder(),
          );
        }
      } catch (e) {
        // Fallback if File operations fail
      }
    }
    
    return _imageErrorPlaceholder();
  }

  Widget _imageErrorPlaceholder() {
    return Container(
      height: 220,
      color: const Color(0xFFE8E0D8),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 48, color: Color(0xFFADADAD)),
      ),
    );
  }
}

// ── Twist change summary banner ────────────────────────────────────────────

class _TwistChangeSummary extends StatefulWidget {
  final Recipe recipe;
  const _TwistChangeSummary({required this.recipe});

  @override
  State<_TwistChangeSummary> createState() => _TwistChangeSummaryState();
}

class _TwistChangeSummaryState extends State<_TwistChangeSummary> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

    final added = recipe.ingredients
        .where((i) => i.status == IngredientStatus.added)
        .map((i) => i.label)
        .toList();
    final removed = recipe.ingredients
        .where((i) => i.status == IngredientStatus.removed)
        .map((i) => i.label)
        .toList();
    final modified = recipe.ingredients
        .where((i) => i.status == IngredientStatus.modified)
        .toList();

    final stepsAdded = recipe.steps
        .where((s) => s.status == StepStatus.added)
        .length;
    final stepsModified = recipe.steps
        .where((s) => s.status == StepStatus.modified)
        .length;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC8956C), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right_rounded,
                        size: 16, color: Color(0xFFC8956C)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Twist of: ${recipe.parentRecipeName}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC8956C),
                        ),
                      ),
                    ),
                    // Count badges
                    if (added.isNotEmpty)
                      _CountBadge(
                          label: '+${added.length}',
                          color: _DiffColors.addedBorder),
                    if (modified.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _CountBadge(
                          label: '~${modified.length}',
                          color: _DiffColors.modifiedBorder),
                    ],
                    if (removed.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _CountBadge(
                          label: '−${removed.length}',
                          color: _DiffColors.removedBorder),
                    ],
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 20, color: Color(0xFFC8956C)),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expandable body ───────────────────────────────────────────
            if (_expanded) ...[
              const Divider(
                  height: 1, thickness: 1, color: Color(0xFFEDD9C5)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ingredients section
                    const Text(
                      'INGREDIENTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFBBAA99),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (added.isNotEmpty)
                      _ChangeRow(
                        symbol: '+',
                        color: _DiffColors.addedBorder,
                        text: added.join(', '),
                      ),
                    if (modified.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      ...modified.map(
                        (i) => _ChangeRow(
                          symbol: '~',
                          color: _DiffColors.modifiedBorder,
                          text: '${i.originalLabel} → ${i.label}',
                        ),
                      ),
                    ],
                    if (removed.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      _ChangeRow(
                        symbol: '−',
                        color: _DiffColors.removedBorder,
                        text: removed.join(', '),
                      ),
                    ],

                    // Steps section
                    if (stepsAdded > 0 || stepsModified > 0) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'PROCEDURE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFBBAA99),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (stepsAdded > 0)
                        _ChangeRow(
                          symbol: '+',
                          color: _DiffColors.addedBorder,
                          text: '$stepsAdded new step${stepsAdded > 1 ? 's' : ''} added',
                        ),
                      if (stepsModified > 0) ...[
                        const SizedBox(height: 5),
                        _ChangeRow(
                          symbol: '~',
                          color: _DiffColors.modifiedBorder,
                          text: '$stepsModified step${stepsModified > 1 ? 's' : ''} modified',
                        ),
                      ],
                    ],

                    // Legend
                    const SizedBox(height: 12),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFEDD9C5)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: const [
                        _LegendDot(
                            color: _DiffColors.addedBorder, label: 'Added'),
                        _LegendDot(
                            color: _DiffColors.modifiedBorder,
                            label: 'Modified'),
                        _LegendDot(
                            color: _DiffColors.removedBorder,
                            label: 'Removed'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Small helpers for the summary banner ──────────────────────────────────

class _CountBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _CountBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final String symbol;
  final Color color;
  final String text;
  const _ChangeRow(
      {required this.symbol, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(symbol,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF5A5A5A),
                  height: 1.4)),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF888888))),
      ],
    );
  }
}

// ── Tab chip ───────────────────────────────────────────────────────────────

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
            color:
                isSelected ? const Color(0xFF8FA67A) : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  isSelected ? Colors.white : const Color(0xFF888888),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Ingredients tab ────────────────────────────────────────────────────────

class _IngredientsTab extends StatelessWidget {
  final List<RecipeIngredient> ingredients;
  final bool isTwist;

  const _IngredientsTab({
    super.key,
    required this.ingredients,
    required this.isTwist,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    // Legend row at top — only for twists
    if (isTwist) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Wrap(
            spacing: 14,
            runSpacing: 4,
            children: const [
              _LegendDot(
                  color: _DiffColors.addedBorder, label: 'Added'),
              _LegendDot(
                  color: _DiffColors.modifiedBorder, label: 'Modified'),
              _LegendDot(
                  color: _DiffColors.removedBorder, label: 'Removed'),
            ],
          ),
        ),
      );
    }

    // Build 3-per-row grid
    for (int i = 0; i < ingredients.length; i += 3) {
      final rowItems = ingredients.skip(i).take(3).toList();
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: List.generate(3, (col) {
              if (col < rowItems.length) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: col < 2 ? 8 : 0),
                    child: _IngredientChip(ingredient: rowItems[col]),
                  ),
                );
              } else {
                // empty filler so last row aligns
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: col < 2 ? 8 : 0),
                    child: const SizedBox(),
                  ),
                );
              }
            }),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

class _IngredientChip extends StatelessWidget {
  final RecipeIngredient ingredient;
  const _IngredientChip({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final status = ingredient.status;

    final bgColor = switch (status) {
      IngredientStatus.added    => _DiffColors.addedBg,
      IngredientStatus.removed  => _DiffColors.removedBg,
      IngredientStatus.modified => _DiffColors.modifiedBg,
      IngredientStatus.unchanged => _DiffColors.unchangedBg,
    };
    final borderColor = switch (status) {
      IngredientStatus.added    => _DiffColors.addedBorder,
      IngredientStatus.removed  => _DiffColors.removedBorder,
      IngredientStatus.modified => _DiffColors.modifiedBorder,
      IngredientStatus.unchanged => _DiffColors.unchangedBorder,
    };
    final textColor = switch (status) {
      IngredientStatus.added    => _DiffColors.addedText,
      IngredientStatus.removed  => _DiffColors.removedText,
      IngredientStatus.modified => _DiffColors.modifiedText,
      IngredientStatus.unchanged => _DiffColors.unchangedText,
    };
    final IconData? icon = switch (status) {
      IngredientStatus.added    => Icons.add_circle_outline,
      IngredientStatus.removed  => Icons.remove_circle_outline,
      IngredientStatus.modified => Icons.edit_outlined,
      IngredientStatus.unchanged => null,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 10, color: textColor),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  ingredient.label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    decoration: status == IngredientStatus.removed
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: textColor,
                  ),
                ),
              ),
            ],
          ),
          // Show original label for modified
          if (status == IngredientStatus.modified &&
              ingredient.originalLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              ingredient.originalLabel!,
              style: TextStyle(
                fontSize: 9.5,
                color: textColor.withOpacity(0.65),
                decoration: TextDecoration.lineThrough,
                decorationColor: textColor.withOpacity(0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Procedure tab ──────────────────────────────────────────────────────────

class _ProcedureTab extends StatelessWidget {
  final List<RecipeStep> steps;
  final bool isTwist;

  const _ProcedureTab({
    super.key,
    required this.steps,
    required this.isTwist,
  });

  @override
  Widget build(BuildContext context) {
    
    final stepWidgets = steps.asMap().entries.map((e) {
      final step = e.value;
      final status = step.status;

      final bgColor = switch (status) {
        StepStatus.added    => _DiffColors.addedBg,
        StepStatus.removed  => _DiffColors.removedBg,
        StepStatus.modified => _DiffColors.modifiedBg,
        StepStatus.unchanged => Colors.white,
      };
      final borderColor = switch (status) {
        StepStatus.added    => _DiffColors.addedBorder,
        StepStatus.removed  => _DiffColors.removedBorder,
        StepStatus.modified => _DiffColors.modifiedBorder,
        StepStatus.unchanged => const Color(0xFFEAE5DE),
      };
      final circleColor = switch (status) {
        StepStatus.added    => _DiffColors.addedBorder,
        StepStatus.removed  => _DiffColors.removedBorder,
        StepStatus.modified => _DiffColors.modifiedBorder,
        StepStatus.unchanged => const Color(0xFF8FA67A),
      };
      final textColor = switch (status) {
        StepStatus.removed  => _DiffColors.removedText,
        StepStatus.modified => _DiffColors.modifiedText,
        StepStatus.added    => _DiffColors.addedText,
        StepStatus.unchanged => const Color(0xFF4A4A4A),
      };

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: borderColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: circleColor,
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
                      step.text,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        height: 1.5,

                        decoration: status == StepStatus.removed
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              // For modified: show original struck through
              if (status == StepStatus.modified &&
                  step.originalText != null) ...[
                const SizedBox(height: 4),
                Text(
                  step.originalText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _DiffColors.modifiedText.withOpacity(0.6),
                    decoration: TextDecoration.lineThrough,
                    decorationColor:
                        _DiffColors.modifiedText.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
              ],
              // Status pill
              if (status != StepStatus.unchanged) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    switch (status) {
                      StepStatus.added    => '+ New step',
                      StepStatus.removed  => '− Removed',
                      StepStatus.modified => '~ Modified',
                      StepStatus.unchanged => '',
                    },
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: borderColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend — only for twists
        if (isTwist)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Wrap(
              spacing: 14,
              runSpacing: 4,
              children: const [
                _LegendDot(
                    color: _DiffColors.addedBorder, label: 'New step'),
                _LegendDot(
                    color: _DiffColors.modifiedBorder,
                    label: 'Modified step'),
              ],
            ),
          ),

        ...stepWidgets,
      ],
    );
  }
}

// ── Ratings tab ────────────────────────────────────────────────────────────

class _RatingsTab extends StatelessWidget {
  final List<RecipeReview> reviews;
  final double averageRating;
  final int reviewCount;

  const _RatingsTab({
    super.key,
    required this.reviews,
    required this.averageRating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasReviews = reviews.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Average Rating',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8C827A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return Icon(
                          starValue <= averageRating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 20,
                          color: const Color(0xFFC8956C),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$reviewCount ${reviewCount == 1 ? 'rating' : 'ratings'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!hasReviews)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6DDD4)),
            ),
            child: const Text(
              'No ratings yet. Be the first to leave feedback.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B6B6B),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = reviews[index];
              final rating = review.rating;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          review.author.startsWith('@') ? review.author : "@${review.author}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 16,
                              color: const Color(0xFFC8956C),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.comment,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B6B6B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}