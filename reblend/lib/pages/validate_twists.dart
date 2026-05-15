import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added missing import
import '../models/recipe.dart';

// ── Colour palette (mirrors RecipeDetailPage) ─────────────────────────────

class _DiffColors {
  static const addedBg = Color(0xFFE8F5E9);
  static const addedBorder = Color(0xFF8FA67A);
  static const addedText = Color(0xFF4A7C59);

  static const removedBg = Color(0xFFFFEBEE);
  static const removedBorder = Color(0xFFE57373);
  static const removedText = Color(0xFFC62828);

  static const modifiedBg = Color(0xFFFFF8E1);
  static const modifiedBorder = Color(0xFFFFB74D);
  static const modifiedText = Color(0xFFE65100);

  static const unchangedBg = Colors.white;
  static const unchangedBorder = Color(0xFFDDD8D0);
  static const unchangedText = Color(0xFF4A4A4A);
}

// ═══════════════════════════════════════════════════════════════════════════
// VALIDATE TWISTS PAGE
// ═══════════════════════════════════════════════════════════════════════════

class ValidateTwistsPage extends StatefulWidget {
  const ValidateTwistsPage({super.key});

  @override
  State<ValidateTwistsPage> createState() => _ValidateTwistsPageState();
}

class _ValidateTwistsPageState extends State<ValidateTwistsPage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _selectedTab = 0; // 0 = Ingredients, 1 = Procedure

  Offset _dragOffset = Offset.zero;
  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  bool _isSwiping = false;

  double get _rejectOpacity =>
      (_dragOffset.dx < 0 ? (-_dragOffset.dx / 150).clamp(0.0, 1.0) : 0.0);
  double get _approveOpacity =>
      (_dragOffset.dx > 0 ? (_dragOffset.dx / 150).clamp(0.0, 1.0) : 0.0);

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) =>
      setState(() => _dragOffset += d.delta);

  void _onDragEnd(DragEndDetails _, int totalTwists) {
    if (_dragOffset.dx > 120) {
      _animateSwipe(true, totalTwists);
    } else if (_dragOffset.dx < -120) {
      _animateSwipe(false, totalTwists);
    } else {
      _snapBack();
    }
  }

  void _animateSwipe(bool approve, int totalTwists) {
    _isSwiping = true;
    final endX = approve ? 700.0 : -700.0;
    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(endX, _dragOffset.dy + (approve ? -60 : 60)),
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    _swipeController.forward(from: 0).then((_) {
      setState(() {
        if (totalTwists > 0) {
          _currentIndex = (_currentIndex + 1) % totalTwists;
        }
        _dragOffset = Offset.zero;
        _isSwiping = false;
        _selectedTab = 0;
      });
      _swipeController.reset();
    });
  }

  void _snapBack() {
    _isSwiping = true;
    _swipeAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _swipeController, curve: Curves.elasticOut),
        );

    _swipeController.forward(from: 0).then((_) {
      setState(() {
        _dragOffset = Offset.zero;
        _isSwiping = false;
      });
      _swipeController.reset();
    });
  }

  void _buttonSwipe(bool approve, int totalTwists) {
    if (_isSwiping || totalTwists == 0) return;
    setState(() => _dragOffset = Offset(approve ? 20 : -20, 0));
    _animateSwipe(approve, totalTwists);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes')
          .where('hasTwist', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F1EC),
            body: Center(
              child: Text(
                'No twists to validate.',
                style: TextStyle(color: Color(0xFFADADAD)),
              ),
            ),
          );
        }

        final twists = snapshot.data!.docs
            .map(
              (doc) => Recipe.fromFirestore(
                doc.id,
                doc.data() as Map<String, dynamic>,
              ),
            )
            .toList();

        // Safety check for index
        if (_currentIndex >= twists.length) {
          _currentIndex = 0;
        }

        final twist = twists[_currentIndex];

        return Scaffold(
          backgroundColor: const Color(0xFFF5F1EC),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(twists.length),
                Expanded(
                  child: Stack(
                    children: [
                      // Back card peek
                      if (twists.length > 1)
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                            child: Transform.scale(
                              scale: 0.95,
                              child: _buildCard(
                                twists[(_currentIndex + 1) % twists.length],
                                isBack: true,
                              ),
                            ),
                          ),
                        ),

                      // Main draggable card
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                          child: GestureDetector(
                            onPanUpdate: _isSwiping ? null : _onDragUpdate,
                            onPanEnd: _isSwiping
                                ? null
                                : (d) => _onDragEnd(d, twists.length),
                            child: AnimatedBuilder(
                              animation: _swipeController,
                              builder: (_, _) {
                                final offset = _isSwiping
                                    ? _swipeAnimation.value
                                    : _dragOffset;
                                final angle = (offset.dx / 400).clamp(
                                  -0.25,
                                  0.25,
                                );
                                return Transform.translate(
                                  offset: offset,
                                  child: Transform.rotate(
                                    angle: angle,
                                    child: Stack(
                                      children: [
                                        _buildCard(twist),
                                        if (_rejectOpacity > 0)
                                          _buildSwipeOverlay(
                                            label: 'NOPE',
                                            color: const Color(0xFFE57373),
                                            opacity: _rejectOpacity,
                                          ),
                                        if (_approveOpacity > 0)
                                          _buildSwipeOverlay(
                                            label: 'APPROVE',
                                            color: const Color(0xFF8FA67A),
                                            opacity: _approveOpacity,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // Action buttons
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: _buildActionButtons(twists.length),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          const Spacer(),
          const Text(
            'Validate Twists',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E2E2E),
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(
              count,
              (i) => Container(
                margin: const EdgeInsets.only(left: 4),
                width: i == _currentIndex ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _currentIndex
                      ? const Color(0xFF8FA67A)
                      : const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Swipe overlay ────────────────────────────────────────────────────────

  Widget _buildSwipeOverlay({
    required String label,
    required Color color,
    required double opacity,
  }) {
    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.25),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Card ─────────────────────────────────────────────────────────────────

  Widget _buildCard(Recipe twist, {bool isBack = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isBack ? 0.04 : 0.10),
            blurRadius: isBack ? 8 : 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              children: [
                Text(
                  twist.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${twist.author}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8FA67A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (twist.parentRecipeAuthor != null)
                  Text(
                    'Orig. recipe by @${twist.parentRecipeAuthor}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFADADAD),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  twist.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFE8E0D0),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: Color(0xFFADADAD),
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              children: [
                _buildChangeSummaryBadges(twist),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE5DE),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      _TabChip(
                        label: 'Ingredients',
                        isSelected: _selectedTab == 0,
                        onTap: isBack
                            ? null
                            : () => setState(() => _selectedTab = 0),
                      ),
                      _TabChip(
                        label: 'Procedure',
                        isSelected: _selectedTab == 1,
                        onTap: isBack
                            ? null
                            : () => setState(() => _selectedTab = 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: _selectedTab == 0
                  ? _IngredientsTab(ingredients: twist.ingredients)
                  : _ProcedureTab(steps: twist.steps),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeSummaryBadges(Recipe twist) {
    final added = twist.ingredients
        .where((i) => i.status == IngredientStatus.added)
        .length;
    final removed = twist.ingredients
        .where((i) => i.status == IngredientStatus.removed)
        .length;
    final modified = twist.ingredients
        .where((i) => i.status == IngredientStatus.modified)
        .length;
    final stepsChanged = twist.steps
        .where((s) => s.status != StepStatus.unchanged)
        .length;

    if (added == 0 && removed == 0 && modified == 0 && stepsChanged == 0) {
      return const SizedBox.shrink();
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        if (added > 0)
          _Badge(
            label: '+$added item${added > 1 ? 's' : ''}',
            color: _DiffColors.addedBorder,
          ),
        if (modified > 0)
          _Badge(
            label: '~$modified changed',
            color: _DiffColors.modifiedBorder,
          ),
        if (removed > 0)
          _Badge(label: '−$removed removed', color: _DiffColors.removedBorder),
      ],
    );
  }

  Widget _buildActionButtons(int totalTwists) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _buttonSwipe(false, totalTwists),
          child: const _ActionButton(
            icon: Icons.close_rounded,
            color: Color(0xFFC8956C),
          ),
        ),
        const SizedBox(width: 48),
        GestureDetector(
          onTap: () => _buttonSwipe(true, totalTwists),
          child: const _ActionButton(
            icon: Icons.check_rounded,
            color: Color(0xFF8FA67A),
          ),
        ),
      ],
    );
  }
}

// Keep your existing _IngredientsTab, _ProcedureTab, _TabChip, etc. here...
// (I am omitting them for brevity but they remain identical to your previous code)

class _IngredientsTab extends StatelessWidget {
  final List<RecipeIngredient> ingredients;
  const _IngredientsTab({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Wrap(
          spacing: 12,
          runSpacing: 4,
          children: const [
            _LegendDot(color: _DiffColors.addedBorder, label: 'Added'),
            _LegendDot(color: _DiffColors.modifiedBorder, label: 'Modified'),
            _LegendDot(color: _DiffColors.removedBorder, label: 'Removed'),
          ],
        ),
      ),
    ];

    for (int i = 0; i < ingredients.length; i += 3) {
      final rowItems = ingredients.skip(i).take(3).toList();
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: List.generate(3, (col) {
              if (col < rowItems.length) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: col < 2 ? 8 : 0),
                    child: _IngredientChip(ingredient: rowItems[col]),
                  ),
                );
              }
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: col < 2 ? 8 : 0),
                  child: const SizedBox(),
                ),
              );
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
    final s = ingredient.status;
    final bg = switch (s) {
      IngredientStatus.added => _DiffColors.addedBg,
      IngredientStatus.removed => _DiffColors.removedBg,
      IngredientStatus.modified => _DiffColors.modifiedBg,
      IngredientStatus.unchanged => _DiffColors.unchangedBg,
    };
    final border = switch (s) {
      IngredientStatus.added => _DiffColors.addedBorder,
      IngredientStatus.removed => _DiffColors.removedBorder,
      IngredientStatus.modified => _DiffColors.modifiedBorder,
      IngredientStatus.unchanged => _DiffColors.unchangedBorder,
    };
    final text = switch (s) {
      IngredientStatus.added => _DiffColors.addedText,
      IngredientStatus.removed => _DiffColors.removedText,
      IngredientStatus.modified => _DiffColors.modifiedText,
      IngredientStatus.unchanged => _DiffColors.unchangedText,
    };
    final IconData? icon = switch (s) {
      IngredientStatus.added => Icons.add_circle_outline,
      IngredientStatus.removed => Icons.remove_circle_outline,
      IngredientStatus.modified => Icons.edit_outlined,
      IngredientStatus.unchanged => null,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 10, color: text),
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
                    color: text,
                    decoration: s == IngredientStatus.removed
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: text,
                  ),
                ),
              ),
            ],
          ),
          if (s == IngredientStatus.modified &&
              ingredient.originalLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              ingredient.originalLabel!,
              style: TextStyle(
                fontSize: 9.5,
                color: text.withOpacity(0.6),
                decoration: TextDecoration.lineThrough,
                decorationColor: text.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProcedureTab extends StatelessWidget {
  final List<RecipeStep> steps;
  const _ProcedureTab({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            children: const [
              _LegendDot(color: _DiffColors.addedBorder, label: 'New step'),
              _LegendDot(color: _DiffColors.modifiedBorder, label: 'Modified'),
              _LegendDot(color: _DiffColors.removedBorder, label: 'Removed'),
            ],
          ),
        ),
        ...steps.asMap().entries.map((e) {
          final step = e.value;
          final s = step.status;

          final bg = switch (s) {
            StepStatus.added => _DiffColors.addedBg,
            StepStatus.removed => _DiffColors.removedBg,
            StepStatus.modified => _DiffColors.modifiedBg,
            StepStatus.unchanged => Colors.white,
          };
          final border = switch (s) {
            StepStatus.added => _DiffColors.addedBorder,
            StepStatus.removed => _DiffColors.removedBorder,
            StepStatus.modified => _DiffColors.modifiedBorder,
            StepStatus.unchanged => const Color(0xFFEAE5DE),
          };
          final circle = switch (s) {
            StepStatus.added => _DiffColors.addedBorder,
            StepStatus.removed => _DiffColors.removedBorder,
            StepStatus.modified => _DiffColors.modifiedBorder,
            StepStatus.unchanged => const Color(0xFF8FA67A),
          };
          final textColor = switch (s) {
            StepStatus.added => _DiffColors.addedText,
            StepStatus.removed => _DiffColors.removedText,
            StepStatus.modified => _DiffColors.modifiedText,
            StepStatus.unchanged => const Color(0xFF4A4A4A),
          };

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: border, width: 4),
                  top: BorderSide(color: border.withOpacity(0.3)),
                  right: BorderSide(color: border.withOpacity(0.3)),
                  bottom: BorderSide(color: border.withOpacity(0.3)),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: circle,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (s == StepStatus.modified &&
                            step.originalText != null) ...[
                          Text(
                            step.originalText!,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: _DiffColors.modifiedText.withOpacity(0.6),
                              decoration: TextDecoration.lineThrough,
                              decorationColor: _DiffColors.modifiedText
                                  .withOpacity(0.6),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                        ],
                        Text(
                          step.text,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: textColor,
                            height: 1.45,
                            decoration: s == StepStatus.removed
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  const _TabChip({required this.label, required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _ActionButton({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 32),
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
        ),
      ],
    );
  }
}
