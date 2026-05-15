import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

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

class ValidateTwistsPage extends StatefulWidget {
  const ValidateTwistsPage({super.key});

  @override
  State<ValidateTwistsPage> createState() => _ValidateTwistsPageState();
}

class _ValidateTwistsPageState extends State<ValidateTwistsPage>
    with TickerProviderStateMixin {

  int _currentIndex = 0;
  int _selectedTab = 0;

  // ── Drag state ─────────────────────────────────────────
  Offset _dragOffset = Offset.zero;
  bool _isAnimating = false;

  late AnimationController _flyController;
  late AnimationController _snapController;
  Animation<Offset>? _flyAnimation;
  Animation<Offset>? _snapAnimation;

  // ── Overlay opacities ──────────────────────────────────
  double get _rejectOpacity =>
      (_dragOffset.dx < 0 ? (-_dragOffset.dx / 130).clamp(0.0, 1.0) : 0.0);
  double get _approveOpacity =>
      (_dragOffset.dx > 0 ? (_dragOffset.dx / 130).clamp(0.0, 1.0) : 0.0);

  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _flyController.dispose();
    _snapController.dispose();
    super.dispose();
  }

  // ── Drag handlers ──────────────────────────────────────
  void _onDragUpdate(DragUpdateDetails d) {
    if (_isAnimating) return;
    setState(() => _dragOffset += d.delta);
  }

  void _onDragEnd(DragEndDetails _, int total) {
    if (_isAnimating) return;
    if (_dragOffset.dx > 110) {
      _flyOut(approve: true, total: total);
    } else if (_dragOffset.dx < -110) {
      _flyOut(approve: false, total: total);
    } else {
      _snapBack();
    }
  }

  // ── Fly off screen ─────────────────────────────────────
  Future<void> _flyOut({required bool approve, required int total}) async {
    if (_isAnimating || total == 0) return;
    setState(() => _isAnimating = true);

    final endX  = approve ? 800.0 : -800.0;
    final endY  = _dragOffset.dy + (approve ? -80.0 : 80.0);

    _flyController.reset();
    _flyAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(endX, endY),
    ).animate(CurvedAnimation(parent: _flyController, curve: Curves.easeInCubic));

    await _flyController.forward();

    // ── approve → validate in Firestore; reject → just skip ──
    // (recipe stays in Firestore either way; only approve marks validated:true)
    setState(() {
      _currentIndex = (_currentIndex + 1) % total;
      _dragOffset   = Offset.zero;
      _selectedTab  = 0;
      _isAnimating  = false;
    });
    _flyController.reset();
  }

  // ── Snap back to centre ────────────────────────────────
  Future<void> _snapBack() async {
    if (_isAnimating) return;
    setState(() => _isAnimating = true);

    _snapController.reset();
    _snapAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _snapController, curve: Curves.elasticOut));

    await _snapController.forward();

    setState(() {
      _dragOffset  = Offset.zero;
      _isAnimating = false;
    });
    _snapController.reset();
  }

  // ── Button triggers ────────────────────────────────────
  Future<void> _handleApprove(List<Recipe> twists) async {
    if (_isAnimating || twists.isEmpty) return;
    final twist = twists[_currentIndex];
    await RecipeService().validateTwist(twist.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${twist.name}" approved and now visible on the home screen!'),
          backgroundColor: const Color(0xFF8FA67A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    await _flyOut(approve: true, total: twists.length);
  }

  Future<void> _handleReject(List<Recipe> twists) async {
    if (_isAnimating || twists.isEmpty) return;
    // Just skip — recipe stays in Firestore, not deleted
    await _flyOut(approve: false, total: twists.length);
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F1EC),
        body: Center(child: Text('Please log in to validate twists.')),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes')
          .where('hasTwist', isEqualTo: true)
          .where('validated', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F1EC),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF8FA67A)),
            ),
          );
        }

        if (snapshot.hasError) {
          // validated field may not exist yet — fall back gracefully
          return const Scaffold(
            backgroundColor: Color(0xFFF5F1EC),
            body: Center(child: Text('Error loading twists.')),
          );
        }

        // ── Only show twists where the parent recipe belongs to currentUser
        final allTwists = (snapshot.data?.docs ?? [])
            .map((doc) => Recipe.fromFirestore(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ))
            .where((r) => r.parentUserId == currentUid)
            .toList();

        if (allTwists.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F1EC),
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(0),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAE5DE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 40,
                              color: Color(0xFF8FA67A),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'All caught up!',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E2E2E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No twists pending validation.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Clamp index
        final safeIndex = _currentIndex.clamp(0, allTwists.length - 1);
        if (_currentIndex != safeIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _currentIndex = safeIndex);
          });
        }

        final twist = allTwists[safeIndex];

        return Scaffold(
          backgroundColor: const Color(0xFFF5F1EC),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(allTwists.length),
                Expanded(
                  child: Stack(
                    children: [
                      // ── Back card peek ──────────────────────────
                      if (allTwists.length > 1)
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(28, 8, 28, 104),
                            child: Transform.scale(
                              scale: 0.94,
                              child: Opacity(
                                opacity: 0.6,
                                child: _buildCard(
                                  allTwists[(safeIndex + 1) % allTwists.length],
                                  isBack: true,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // ── Main draggable card ─────────────────────
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
                          child: GestureDetector(
                            onPanUpdate: _isAnimating ? null : _onDragUpdate,
                            onPanEnd: _isAnimating
                                ? null
                                : (d) => _onDragEnd(d, allTwists.length),
                            child: AnimatedBuilder(
                              animation: Listenable.merge([
                                _flyController,
                                _snapController,
                              ]),
                              builder: (_, __) {
                                Offset offset = _dragOffset;
                                if (_flyController.isAnimating &&
                                    _flyAnimation != null) {
                                  offset = _flyAnimation!.value;
                                } else if (_snapController.isAnimating &&
                                    _snapAnimation != null) {
                                  offset = _snapAnimation!.value;
                                }

                                final angle =
                                    (offset.dx / 380).clamp(-0.22, 0.22);

                                return Transform.translate(
                                  offset: offset,
                                  child: Transform.rotate(
                                    angle: angle,
                                    child: Stack(
                                      children: [
                                        _buildCard(twist),
                                        if (_rejectOpacity > 0)
                                          _buildOverlay(
                                            label: 'SKIP',
                                            color: const Color(0xFFC8956C),
                                            opacity: _rejectOpacity,
                                            icon: Icons.arrow_forward_rounded,
                                          ),
                                        if (_approveOpacity > 0)
                                          _buildOverlay(
                                            label: 'APPROVE',
                                            color: const Color(0xFF8FA67A),
                                            opacity: _approveOpacity,
                                            icon: Icons.check_rounded,
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

                      // ── Action buttons ──────────────────────────
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: _buildActionButtons(allTwists),
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

  // ── Header ─────────────────────────────────────────────

  Widget _buildHeader(int count) {
  final canPop = Navigator.of(context).canPop();  // ← check first

  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
    child: Row(
      children: [
        if (canPop)                                // ← only show if there's something to pop
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: Color(0xFF4A4A4A)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )
        else
          const SizedBox(width: 40),              // ← keep layout balanced
        const Spacer(),
        Column(
          children: [
            const Text(
              'Validate Twists',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E2E2E),
              ),
            ),
            if (count > 0)
              Text(
                '$count pending',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                ),
              ),
          ],
        ),
        const Spacer(),
        if (count > 0)
          Row(
            children: List.generate(count.clamp(0, 6), (i) {
              final isActive = i == _currentIndex % count.clamp(1, 6);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(left: 4),
                width: isActive ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF8FA67A)
                      : const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          )
        else
          const SizedBox(width: 40),
      ],
    ),
  );
}

  // ── Overlay ────────────────────────────────────────────

  Widget _buildOverlay({
    required String label,
    required Color color,
    required double opacity,
    required IconData icon,
  }) {
    return Positioned.fill(
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Align(
            alignment: label == 'SKIP'
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  border: Border.all(color: color, width: 2.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Card ───────────────────────────────────────────────

  Widget _buildCard(Recipe twist, {bool isBack = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isBack ? 0.05 : 0.12),
            blurRadius: isBack ? 10 : 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Image ───────────────────────────────────────
          AspectRatio(
            aspectRatio: 16 / 8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  twist.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE8E0D0),
                    child: const Icon(Icons.restaurant_menu,
                        color: Color(0xFFADADAD), size: 40),
                  ),
                ),
                // Gradient overlay for text legibility
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Name + author on image
                Positioned(
                  bottom: 12,
                  left: 14,
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        twist.name,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black38),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            '@${twist.author}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (twist.parentRecipeName != null) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.subdirectory_arrow_right_rounded,
                                size: 12, color: Color(0xFFFFCC80)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                'twist of "${twist.parentRecipeName}"',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFFFCC80),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Change badges ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: _buildChangeBadges(twist),
          ),

          // ── Tab bar ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Container(
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
                    onTap: isBack ? null : () => setState(() => _selectedTab = 0),
                  ),
                  _TabChip(
                    label: 'Procedure',
                    isSelected: _selectedTab == 1,
                    onTap: isBack ? null : () => setState(() => _selectedTab = 1),
                  ),
                ],
              ),
            ),
          ),

          // ── Tab content ─────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _selectedTab == 0
                    ? _IngredientsTab(
                        key: const ValueKey(0),
                        ingredients: twist.ingredients,
                      )
                    : _ProcedureTab(
                        key: const ValueKey(1),
                        steps: twist.steps,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeBadges(Recipe twist) {
    final added    = twist.ingredients.where((i) => i.status == IngredientStatus.added).length;
    final removed  = twist.ingredients.where((i) => i.status == IngredientStatus.removed).length;
    final modified = twist.ingredients.where((i) => i.status == IngredientStatus.modified).length;
    final stepsChanged = twist.steps.where((s) => s.status != StepStatus.unchanged).length;

    if (added == 0 && removed == 0 && modified == 0 && stepsChanged == 0) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (added > 0)
          _Badge(label: '+$added added', color: _DiffColors.addedBorder),
        if (modified > 0)
          _Badge(label: '~$modified modified', color: _DiffColors.modifiedBorder),
        if (removed > 0)
          _Badge(label: '−$removed removed', color: _DiffColors.removedBorder),
        if (stepsChanged > 0)
          _Badge(
            label: '$stepsChanged step${stepsChanged > 1 ? 's' : ''} changed',
            color: const Color(0xFF8FA67A),
          ),
      ],
    );
  }

  // ── Action buttons ─────────────────────────────────────

  Widget _buildActionButtons(List<Recipe> twists) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Skip (does NOT delete)
          Column(
            children: [
              GestureDetector(
                onTap: () => _handleReject(twists),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFC8956C),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC8956C).withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Color(0xFFC8956C), size: 28),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFC8956C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Approve (validates + shows on home screen)
          Column(
            children: [
              GestureDetector(
                onTap: () => _handleApprove(twists),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8FA67A),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8FA67A).withOpacity(0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 34),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Approve',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8FA67A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _IngredientsTab extends StatelessWidget {
  final List<RecipeIngredient> ingredients;
  const _IngredientsTab({super.key, required this.ingredients});

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
      IngredientStatus.added    => _DiffColors.addedBg,
      IngredientStatus.removed  => _DiffColors.removedBg,
      IngredientStatus.modified => _DiffColors.modifiedBg,
      IngredientStatus.unchanged => _DiffColors.unchangedBg,
    };
    final border = switch (s) {
      IngredientStatus.added    => _DiffColors.addedBorder,
      IngredientStatus.removed  => _DiffColors.removedBorder,
      IngredientStatus.modified => _DiffColors.modifiedBorder,
      IngredientStatus.unchanged => _DiffColors.unchangedBorder,
    };
    final text = switch (s) {
      IngredientStatus.added    => _DiffColors.addedText,
      IngredientStatus.removed  => _DiffColors.removedText,
      IngredientStatus.modified => _DiffColors.modifiedText,
      IngredientStatus.unchanged => _DiffColors.unchangedText,
    };
    final IconData? icon = switch (s) {
      IngredientStatus.added    => Icons.add_circle_outline,
      IngredientStatus.removed  => Icons.remove_circle_outline,
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
          if (s == IngredientStatus.modified && ingredient.originalLabel != null) ...[
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
  const _ProcedureTab({super.key, required this.steps});

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
              _LegendDot(color: _DiffColors.addedBorder,    label: 'New step'),
              _LegendDot(color: _DiffColors.modifiedBorder, label: 'Modified'),
              _LegendDot(color: _DiffColors.removedBorder,  label: 'Removed'),
            ],
          ),
        ),
        ...steps.asMap().entries.map((e) {
          final step = e.value;
          final s    = step.status;

          final bg = switch (s) {
            StepStatus.added    => _DiffColors.addedBg,
            StepStatus.removed  => _DiffColors.removedBg,
            StepStatus.modified => _DiffColors.modifiedBg,
            StepStatus.unchanged => Colors.white,
          };
          final border = switch (s) {
            StepStatus.added    => _DiffColors.addedBorder,
            StepStatus.removed  => _DiffColors.removedBorder,
            StepStatus.modified => _DiffColors.modifiedBorder,
            StepStatus.unchanged => const Color(0xFFEAE5DE),
          };
          final circle = switch (s) {
            StepStatus.added    => _DiffColors.addedBorder,
            StepStatus.removed  => _DiffColors.removedBorder,
            StepStatus.modified => _DiffColors.modifiedBorder,
            StepStatus.unchanged => const Color(0xFF8FA67A),
          };
          final textColor = switch (s) {
            StepStatus.added    => _DiffColors.addedText,
            StepStatus.removed  => _DiffColors.removedText,
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
                  top: BorderSide(color: border.withOpacity(0.25)),
                  right: BorderSide(color: border.withOpacity(0.25)),
                  bottom: BorderSide(color: border.withOpacity(0.25)),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(color: circle, shape: BoxShape.circle),
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
                        if (s == StepStatus.modified && step.originalText != null) ...[
                          Text(
                            step.originalText!,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: _DiffColors.modifiedText.withOpacity(0.6),
                              decoration: TextDecoration.lineThrough,
                              decorationColor: _DiffColors.modifiedText.withOpacity(0.6),
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
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
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
      ],
    );
  }
}