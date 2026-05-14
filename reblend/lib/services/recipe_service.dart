import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _recipesCollection = 'recipes';

  /// Add a new recipe to Firestore
  Future<String> addRecipe({
    required String name,
    required String category,
    required int cookTimeMinutes,
    required List<RecipeIngredient> ingredients,
    required List<RecipeStep> steps,
    required String imagePath,
    String author = 'user',
  }) async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';

      final recipeData = {
        'name': name,
        'category': category,
        'cookTimeMinutes': cookTimeMinutes,
        'author': author,
        'date': dateStr,
        'imageUrl': imagePath,
        'ingredients': ingredients.map((ing) => ing.label).toList(),
        'steps': steps.map((step) => step.text).toList(),
        'rating': 0.0,
        'reviewCount': 0,
        'hasTwist': false,
        'parentRecipeId': null,
        'parentRecipeName': null,
        'parentRecipeAuthor': null,
        'reviews': [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection(_recipesCollection).add(recipeData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add recipe: $e');
    }
  }

  /// Get all recipes from Firestore
  Future<List<Recipe>> getAllRecipes() async {
    try {
      final querySnapshot =
          await _firestore.collection(_recipesCollection).get();
      return querySnapshot.docs.map((doc) => _documentToRecipe(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recipes: $e');
    }
  }

  /// Get recipes by category
  Future<List<Recipe>> getRecipesByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_recipesCollection)
          .where('category', isEqualTo: category)
          .get();
      return querySnapshot.docs.map((doc) => _documentToRecipe(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recipes by category: $e');
    }
  }

  /// Get a single recipe by ID
  Future<Recipe?> getRecipeById(String recipeId) async {
    try {
      final doc =
          await _firestore.collection(_recipesCollection).doc(recipeId).get();
      if (doc.exists) {
        return _documentToRecipe(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch recipe: $e');
    }
  }

  /// Add a twist (variant) of an existing recipe
  Future<String> addTwist({
    required String parentRecipeId,
    required String twistName,
    required List<RecipeIngredient> modifiedIngredients,
    required List<RecipeStep> modifiedSteps,
    String author = 'user',
  }) async {
    try {
      final parentRecipe = await getRecipeById(parentRecipeId);
      if (parentRecipe == null) {
        throw Exception('Parent recipe not found');
      }

      final now = DateTime.now();
      final dateStr =
          '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';

      final twistData = {
        'name': twistName,
        'category': parentRecipe.imageUrl, // Keep category from parent
        'cookTimeMinutes': 0, // Could be updated by user
        'author': author,
        'date': dateStr,
        'imageUrl': '',
        'ingredients': modifiedIngredients.map((ing) => ing.label).toList(),
        'steps': modifiedSteps.map((step) => step.text).toList(),
        'rating': 0.0,
        'reviewCount': 0,
        'hasTwist': true,
        'parentRecipeId': parentRecipeId,
        'parentRecipeName': parentRecipe.name,
        'parentRecipeAuthor': parentRecipe.author,
        'reviews': [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection(_recipesCollection).add(twistData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add twist: $e');
    }
  }

  /// Helper method to convert Firestore document to Recipe object
  Recipe _documentToRecipe(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final ingredientLabels = List<String>.from(data['ingredients'] ?? []);
    final ingredients = ingredientLabels
        .map((label) => RecipeIngredient(label: label))
        .toList();

    final stepTexts = List<String>.from(data['steps'] ?? []);

    final steps =
        stepTexts.map((text) => RecipeStep(text: text)).toList();

    final reviewDocs = List<Map<String, dynamic>>.from(data['reviews'] ?? []);
    final reviews = reviewDocs
        .map((reviewData) => RecipeReview(
              author: reviewData['author'] ?? 'Anonymous',
              rating: (reviewData['rating'] ?? 0).toDouble(),
              comment: reviewData['comment'] ?? '',
            ))
        .toList();

    return Recipe(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      author: data['author'] ?? 'Unknown',
      date: data['date'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      hasTwist: data['hasTwist'] ?? false,
      parentRecipeId: data['parentRecipeId'],
      parentRecipeName: data['parentRecipeName'],
      parentRecipeAuthor: data['parentRecipeAuthor'],
      ingredients: ingredients,
      steps: steps,
      reviews: reviews,
    );
  }
}
