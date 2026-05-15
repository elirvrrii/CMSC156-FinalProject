import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import '../models/recipe.dart';
import '../pages/add_recipe_page.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback? onRatingTap;
  final VoidCallback? onTwistTap;
  final bool isOwner; 

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.onRatingTap,
    this.onTwistTap,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with action buttons
           Stack(
  children: [
    ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: _buildRecipeImage(recipe.imageUrl),
    ),
    // Action icons top-right
    if (!isOwner && !recipe.hasTwist)
      Positioned(
        top: 10,
        right: 12,
        child: Row(
          children: [
            GestureDetector(
              onTap: onRatingTap,
              child: _IconButton(icon: Icons.star_border_rounded),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onTwistTap,
              child: _IconButton(icon: Icons.blender_outlined),
            ),
          ],
        ),
      ),
    // Twist badge (optional)
    if (recipe.hasTwist)
      Positioned(
        bottom: 12,
        right: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFC8956C),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Twist',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
  ],
),
            // Info row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            recipe.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E2E2E),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '@${recipe.author}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFADADAD),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        recipe.date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFADADAD),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_border_rounded, size: 15, color: Color(0xFFADADAD)),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.rating} (${recipe.reviewCount}+)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFADADAD),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeImage(String imagePath) {
    // Check if it's a network URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        height: 200,
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
            height: 200,
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
      height: 200,
      color: const Color(0xFFE8E0D8),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 48, color: Color(0xFFADADAD)),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  const _IconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: const Color(0xFFC8956C)),
    );
  }
}