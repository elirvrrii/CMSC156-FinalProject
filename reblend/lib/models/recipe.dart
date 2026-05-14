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
  final String author;
  final String date;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final bool hasTwist;
  final String? parentRecipeId;
  final String? parentRecipeName;
  final String? parentRecipeAuthor;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final List<RecipeReview> reviews;

  const Recipe({
    required this.id,
    required this.name,
    required this.author,
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

// ── Hardcoded sample data ──────────────────────────────────────────────────

final List<Recipe> sampleRecipes = [
  Recipe(
    id: '1',
    name: 'Pasta',
    author: 'user',
    date: '01/01/2026',
    rating: 5.0,
    reviewCount: 130,
    imageUrl:
        'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800&q=80',
    hasTwist: false,
    ingredients: const [
      RecipeIngredient(label: 'Pasta (200g)'),
      RecipeIngredient(label: 'Salt (1 tsp)'),
      RecipeIngredient(label: 'Tomato'),
      RecipeIngredient(label: 'Egg'),
      RecipeIngredient(label: 'Onion'),
      RecipeIngredient(label: 'Pepper'),
      RecipeIngredient(label: 'Sugar'),
      RecipeIngredient(label: 'Garlic'),
    ],
    steps: const [
      RecipeStep(text: 'Boil water with salt and cook pasta until al dente, then drain.'),
      RecipeStep(text: 'Sauté diced onion and garlic in olive oil until softened.'),
      RecipeStep(
          text: 'Add chopped tomatoes, season with salt, pepper, and sugar. Simmer 10 mins.'),
    ],
    reviews: const [
      RecipeReview(author: 'user-2', rating: 5.0, comment: 'nice...'),
      RecipeReview(author: 'user-3', rating: 4.0, comment: 'Delicious recipe!'),
    ],
  ),

  Recipe(
    id: '2',
    name: 'Pasta Primavera',
    author: 'chef_anna',
    date: '15/02/2026',
    rating: 4.8,
    reviewCount: 85,
    imageUrl:
        'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800&q=80',
    hasTwist: true,
    parentRecipeId: '1',
    parentRecipeName: 'Pasta',
    parentRecipeAuthor: 'user',
    ingredients: const [
      RecipeIngredient(
        label: 'Penne (300g)',
        status: IngredientStatus.modified,
        originalLabel: 'Pasta (200g)',
      ),
      RecipeIngredient(label: 'Salt (1 tsp)'),
      RecipeIngredient(label: 'Tomato'),
      RecipeIngredient(label: 'Egg', status: IngredientStatus.removed),
      RecipeIngredient(label: 'Onion'),
      RecipeIngredient(label: 'Pepper'),
      RecipeIngredient(label: 'Sugar'),
      RecipeIngredient(label: 'Garlic'),
      RecipeIngredient(label: 'Zucchini', status: IngredientStatus.added),
      RecipeIngredient(label: 'Bell Pepper', status: IngredientStatus.added),
      RecipeIngredient(label: 'Parmesan', status: IngredientStatus.added),
      RecipeIngredient(label: 'Basil', status: IngredientStatus.added),
    ],
    steps: const [
      RecipeStep(
        text: 'Cook penne until al dente, drain and reserve ½ cup pasta water.',
        status: StepStatus.modified,
        originalText: 'Boil water with salt and cook pasta until al dente, then drain.',
      ),
      RecipeStep(text: 'Sauté diced onion and garlic in olive oil until softened.'),
      RecipeStep(
        text: 'Add zucchini and bell pepper to the pan and sauté for 3–4 minutes until tender.',
        status: StepStatus.added,
      ),
      RecipeStep(
          text: 'Add chopped tomatoes, season with salt, pepper, and sugar. Simmer 10 mins.'),
      RecipeStep(
        text: 'Toss pasta with vegetables, splash of pasta water, top with parmesan and basil.',
        status: StepStatus.added,
      ),
    ],
    reviews: const [
      RecipeReview(author: 'user-5', rating: 5.0, comment: 'Amazing twist!'),
    ],
  ),
];