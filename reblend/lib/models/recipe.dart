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
}