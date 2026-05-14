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

  // Safe factory constructor to parse strings or objects from Firestore
  factory RecipeIngredient.fromDynamic(dynamic item) {
    if (item is String) {
      return RecipeIngredient(label: item, status: IngredientStatus.unchanged);
    } else if (item is Map) {
      return RecipeIngredient(
        label: item['label'] ?? '',
        status: IngredientStatus.values.firstWhere(
          (e) => e.name == (item['status'] ?? 'unchanged'),
          orElse: () => IngredientStatus.unchanged,
        ),
        originalLabel: item['originalLabel'],
      );
    }
    return const RecipeIngredient(label: '');
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

  // Safe factory constructor to parse strings or objects from Firestore
  factory RecipeStep.fromDynamic(dynamic item) {
    if (item is String) {
      return RecipeStep(text: item, status: StepStatus.unchanged);
    } else if (item is Map) {
      return RecipeStep(
        text: item['text'] ?? '',
        status: StepStatus.values.firstWhere(
          (e) => e.name == (item['status'] ?? 'unchanged'),
          orElse: () => StepStatus.unchanged,
        ),
        originalText: item['originalText'],
      );
    }
    return const RecipeStep(text: '');
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

  // Converts a Firestore Map safely into a RecipeReview object
  factory RecipeReview.fromJson(Map<String, dynamic> json) {
    return RecipeReview(
      author: json['author'] ?? 'Chef',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
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

  // ─── ADD THIS FACTORY CONSTRUCTOR TO FIX YOUR CRASHES ───
  factory Recipe.fromJson(Map<String, dynamic> json, String documentId) {
    // Parse ingredients safely
    var rawIngredients = json['ingredients'] as List<dynamic>? ?? [];
    List<RecipeIngredient> parsedIngredients = rawIngredients
        .map((item) => RecipeIngredient.fromDynamic(item))
        .toList();

    // Parse steps safely
    var rawSteps = json['steps'] as List<dynamic>? ?? [];
    List<RecipeStep> parsedSteps = rawSteps
        .map((item) => RecipeStep.fromDynamic(item))
        .toList();

    // Parse reviews safely into your RecipeReview objects
    var rawReviews = json['reviews'] as List<dynamic>? ?? [];
    List<RecipeReview> parsedReviews = rawReviews
        .whereType<Map>()
        .map((item) {
          final reviewMap = Map<String, dynamic>.from(item);
          final ratingValue = reviewMap['rating'];

          return RecipeReview(
            author: reviewMap['author'] ?? 'Chef',
            rating: ratingValue is num ? ratingValue.toDouble() : 0.0,
            comment: reviewMap['comment'] ?? '',
          );
        })
        .toList();

    return Recipe(
      id: documentId,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      author: json['author'] ?? 'Unknown Author',
      userId: json['userId'],
      cookTimeMinutes: json['cookTimeMinutes'] ?? 0,
      date: json['date'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      hasTwist: json['hasTwist'] ?? false,
      parentRecipeId: json['parentRecipeId'],
      parentRecipeName: json['parentRecipeName'],
      parentRecipeAuthor: json['parentRecipeAuthor'],
      ingredients: parsedIngredients,
      steps: parsedSteps,
      reviews: parsedReviews, // 👈 Now correctly typed!
    );
  }
}