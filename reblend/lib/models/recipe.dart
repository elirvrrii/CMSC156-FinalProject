class Recipe {
  final String id;
  final String name;
  final String author;
  final String date;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final bool hasTwist;
  final List<String> ingredients;
  final List<String> steps;
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
    required this.ingredients,
    required this.steps,
    required this.reviews,
  });
}

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

// Hardcoded sample recipes
final List<Recipe> sampleRecipes = [
  Recipe(
    id: '1',
    name: 'Pasta',
    author: 'user',
    date: '01/01/2026',
    rating: 5.0,
    reviewCount: 130,
    imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800&q=80',
    hasTwist: false,
    ingredients: [
      'Pasta (200g)', 'Salt (1 tsp)', 'Tomato', 'Egg',
      'Onion', 'Pepper', 'Sugar', 'Garlic',
    ],
    steps: [
      'Boil water with salt and cook pasta until al dente, then drain.',
      'Sauté diced onion and garlic in olive oil until softened.',
      'Add chopped tomatoes, season with salt, pepper, and sugar. Simmer 10 mins.',
    ],
    reviews: [
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
    imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800&q=80',
    hasTwist: true,
    ingredients: [
      'Penne (200g)', 'Zucchini', 'Bell Pepper', 'Cherry Tomato',
      'Olive Oil', 'Parmesan', 'Basil', 'Garlic',
    ],
    steps: [
      'Cook penne according to package directions.',
      'Sauté vegetables in olive oil until tender.',
      'Toss pasta with vegetables, top with fresh parmesan and basil.',
    ],
    reviews: [
      RecipeReview(author: 'user-5', rating: 5.0, comment: 'Amazing twist!'),
    ],
  ),
];