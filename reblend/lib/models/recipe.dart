// ── Change status enums ────────────────────────────────────────────────────

enum IngredientStatus { unchanged, added, removed, modified }

enum StepStatus { unchanged, added, removed, modified }

// ── Typed ingredient ───────────────────────────────────────────────────────

class RecipeIngredient {
  final String label;
  final IngredientStatus status;
  final String? originalLabel; // only for modified

  const RecipeIngredient({
    required this.label,
    this.status = IngredientStatus.unchanged,
    this.originalLabel,
  });

  // Convert Firestore Map to Object
  factory RecipeIngredient.fromMap(dynamic map) {
    if (map is String) {
      return RecipeIngredient(label: map);
    }
    return RecipeIngredient(
      label: map['label'] ?? '',
      status: IngredientStatus.values.byName(map['status'] ?? 'unchanged'),
      originalLabel: map['originalLabel'],
    );
  }
}

// ── Typed step ─────────────────────────────────────────────────────────────

class RecipeStep {
  final String text;
  final StepStatus status;
  final String? originalText; // only for modified

  const RecipeStep({
    required this.text,
    this.status = StepStatus.unchanged,
    this.originalText,
  });

  factory RecipeStep.fromMap(dynamic map) {
    if (map is String) {
      return RecipeStep(text: map);
    }
    return RecipeStep(
      text: map['text'] ?? '',
      status: StepStatus.values.byName(map['status'] ?? 'unchanged'),
      originalText: map['originalText'],
    );
  }
}

// ── Review ─────────────────────────────────────────────────────────────────

class RecipeReview {
  final String author;
  final double rating;
  final String comment;

  const RecipeReview({
    required this.author,
    required this.rating,
    required this.comment,
  });

  factory RecipeReview.fromMap(Map<String, dynamic> map) {
    return RecipeReview(
      author: map['author'] ?? 'Anonymous',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
    );
  }
}

// ── Recipe ─────────────────────────────────────────────────────────────────

class Recipe {
  final String id;
  final String name;
  final String category;
  final String author;
  final String? userId;
  final String date;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final bool hasTwist;
  final int cookTimeMinutes;
  final String? parentRecipeId;
  final String? parentRecipeName;
  final String? parentRecipeAuthor;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final List<RecipeReview> reviews;

  const Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.author,
    this.userId,
    required this.cookTimeMinutes,
    required this.date,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    this.hasTwist = false,
    this.parentRecipeId,
    this.parentRecipeName,
    this.parentRecipeAuthor,
    required this.ingredients,
    required this.steps,
    required this.reviews,
  });

  factory Recipe.fromFirestore(String id, Map<String, dynamic> data) {
    return Recipe(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      author: data['author'] ?? 'Unknown',
      userId: data['userId'],
      date: data['date'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      cookTimeMinutes: data['cookTimeMinutes'] ?? 0,
      reviewCount: data['reviewCount'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      hasTwist: data['hasTwist'] ?? false,
      parentRecipeId: data['parentRecipeId'],
      parentRecipeName: data['parentRecipeName'],
      parentRecipeAuthor: data['parentRecipeAuthor'],
      ingredients: (data['ingredients'] as List? ?? [])
          .map((i) => RecipeIngredient.fromMap(i))
          .toList(),
      steps: (data['steps'] as List? ?? [])
          .map((s) => RecipeStep.fromMap(s))
          .toList(),
      reviews: (data['reviews'] as List? ?? [])
          .map((r) => RecipeReview.fromMap(Map<String, dynamic>.from(r)))
          .toList(),
    );
  }
}
