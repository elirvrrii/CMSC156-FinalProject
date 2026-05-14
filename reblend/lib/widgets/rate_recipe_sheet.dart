import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

class RateRecipeSheet extends StatefulWidget {
  final Recipe recipe;

  const RateRecipeSheet({super.key, required this.recipe});

  // Helper method to open the sheet easily from your home screen
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
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  final _recipeService = RecipeService();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

Future<void> _submit() async {
    if (_selectedStars == 0) return;
    
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write a comment before submitting.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Fire the database request
      await _recipeService.addRecipeReview(
        recipeId: widget.recipe.id,
        rating: _selectedStars.toDouble(),
        comment: commentText,
      );

      // 💡 THE CRITICAL FIX: Check if this widget is still on screen before doing UI updates
      if (!mounted) return;

      // 2. Safely notify success and dismiss ONLY the bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review submitted successfully!")),
      );
      
      Navigator.of(context).pop(); 
      
    } catch (e) {
      // If something went wrong with Firebase, catch it so the app doesn't crash
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the current user is the owner of the recipe
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid != null && widget.recipe.userId == currentUid;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 12, left: 24, right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFDDD8D0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            isOwner ? 'Recipe Insights' : 'Rate This Recipe',
            style: const TextStyle(
              fontFamily: 'serif', fontSize: 26,
              fontWeight: FontWeight.w700, color: Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Let us know what you think about\n@${widget.recipe.author}\'s recipe!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFFADADAD), height: 1.5),
          ),
          const SizedBox(height: 32),

          // ─── IF OWNER: SHOW LOCK SCREEN ───
          if (isOwner) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0D9CF)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.gavel_rounded, color: Color(0xFFC8956C), size: 36),
                  SizedBox(height: 12),
                  Text(
                    "You cannot rate your own recipe.",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2E2E2E)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "To keep metrics fair, feedback is reserved for your kitchen visitors.",
                    style: TextStyle(fontSize: 12, color: Color(0xFFADADAD)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] 
          // ─── IF VISITOR: SHOW RATING FORM ───
          else ...[
            // Star Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: _isSubmitting ? null : () => setState(() => _selectedStars = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      i < _selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 52, color: const Color(0xFFC8956C),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),

            // Comment Box
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0D9CF)),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 4,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  hintText: 'Enter comment here...',
                  hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity, height: 52,
              child: AnimatedOpacity(
                opacity: (_selectedStars > 0 && !_isSubmitting) ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  onPressed: (_selectedStars > 0 && !_isSubmitting) ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8956C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}