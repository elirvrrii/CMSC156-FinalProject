import 'package:flutter/material.dart';
import '../models/recipe.dart';

class RateRecipeSheet extends StatefulWidget {
  final Recipe recipe;

  const RateRecipeSheet({super.key, required this.recipe});

  // Convenience method to show the sheet
  static void show(BuildContext context, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RateRecipeSheet(recipe: recipe),
    );
  }

  @override
  State<RateRecipeSheet> createState() => _RateRecipeSheetState();
}

class _RateRecipeSheetState extends State<RateRecipeSheet> {
  int _selectedStars = 0;
  int _hoveredStars = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedStars == 0) return;
    // TODO: wire up to your data layer
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final displayStars = _hoveredStars > 0 ? _hoveredStars : _selectedStars;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 12,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFDDD8D0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Text(
            'Rate This Recipe',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E2E2E),
            ),
          ),

          const SizedBox(height: 12),

          // Subtitle
          Text(
            'Let us know what you think about\n@${widget.recipe.author}\'s recipe!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFADADAD),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Star row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < displayStars;
              return GestureDetector(
                onTap: () => setState(() => _selectedStars = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 52,
                    color: filled
                        ? const Color(0xFFC8956C)
                        : const Color(0xFFC8956C),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 28),

          // Comment box
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0D9CF), width: 1),
            ),
            child: TextField(
              controller: _commentController,
              maxLines: 5,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A4A4A),
              ),
              decoration: const InputDecoration(
                hintText: 'Enter comment here',
                hintStyle: TextStyle(
                  color: Color(0xFFBBBBBB),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: AnimatedOpacity(
              opacity: _selectedStars > 0 ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed: _selectedStars > 0 ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8956C),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFC8956C),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}