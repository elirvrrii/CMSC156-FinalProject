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

  static IngredientStatus _parseStatus(dynamic value) {
    return IngredientStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => IngredientStatus.unchanged,
    );
  }

  // Safe factory constructor to parse strings or objects from Firestore.
  factory RecipeIngredient.fromDynamic(dynamic item) => RecipeIngredient.fromMap(item);

  factory RecipeIngredient.fromMap(dynamic map) {
    if (map is String) {
      return RecipeIngredient(label: map, status: IngredientStatus.unchanged);
    }
    final data = map is Map ? Map<String, dynamic>.from(map) : <String, dynamic>{};
    return RecipeIngredient(
      label: data['label'] ?? '',
      status: _parseStatus(data['status'] ?? 'unchanged'),
      originalLabel: data['originalLabel'],
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

  static StepStatus _parseStatus(dynamic value) {
    return StepStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => StepStatus.unchanged,
    );
  }

  // Safe factory constructor to parse strings or objects from Firestore.
  factory RecipeStep.fromDynamic(dynamic item) => RecipeStep.fromMap(item);

  factory RecipeStep.fromMap(dynamic map) {
    if (map is String) {
      return RecipeStep(text: map, status: StepStatus.unchanged);
    }
    final data = map is Map ? Map<String, dynamic>.from(map) : <String, dynamic>{};
    return RecipeStep(
      text: data['text'] ?? '',
      status: _parseStatus(data['status'] ?? 'unchanged'),
      originalText: data['originalText'],
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

  // Converts a Firestore Map safely into a RecipeReview object.
  factory RecipeReview.fromJson(Map<String, dynamic> json) => RecipeReview.fromMap(json);

  factory RecipeReview.fromMap(Map<String, dynamic> map) {
    return RecipeReview(
      author: map['author'] ?? 'Chef',
      rating: (map['rating'] ?? 0.0).toDouble(),
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

  // Build a Recipe from a Firestore document payload.
  factory Recipe.fromJson(Map<String, dynamic> json, String documentId) {
    return Recipe.fromFirestore(documentId, json);
  }

  factory Recipe.fromFirestore(String id, Map<String, dynamic> data) {
    final rawIngredients = data['ingredients'] as List<dynamic>? ?? const [];
    final rawSteps = data['steps'] as List<dynamic>? ?? const [];
    final rawReviews = data['reviews'] as List<dynamic>? ?? const [];

    return Recipe(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      author: data['author'] ?? 'Unknown',
      userId: data['userId'],
      date: data['date'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      cookTimeMinutes: data['cookTimeMinutes'] ?? 0,
      reviewCount: data['reviewCount'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      hasTwist: data['hasTwist'] ?? false,
      parentRecipeId: data['parentRecipeId'],
      parentRecipeName: data['parentRecipeName'],
      parentRecipeAuthor: data['parentRecipeAuthor'],
      ingredients: rawIngredients.map((item) => RecipeIngredient.fromDynamic(item)).toList(),
      steps: rawSteps.map((item) => RecipeStep.fromDynamic(item)).toList(),
      reviews: rawReviews
          .whereType<Map>()
          .map((review) => RecipeReview.fromMap(Map<String, dynamic>.from(review)))
          .toList(),
    );
  }
}
