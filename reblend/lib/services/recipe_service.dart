import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _recipesCollection = 'recipes';

  /// Add a new recipe to Firestore
  Future<String> addRecipe({
    required String name,
    required String category,
    required int cookTimeMinutes,
    required List<RecipeIngredient> ingredients,
    required List<RecipeStep> steps,
    required String imagePath,
    String? author,
    String? userId,
  }) async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';

      // Get current user if userId not provided
      final uid = userId ?? _auth.currentUser?.uid;
      final authorName =
          author ?? _auth.currentUser?.email?.split('@')[0] ?? 'user';

      final recipeData = {
        'name': name,
        'category': category,
        'cookTimeMinutes': cookTimeMinutes,
        'author': authorName,
        'userId': uid, // Attach recipe to user
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

      final docRef = await _firestore
          .collection(_recipesCollection)
          .add(recipeData);

      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({
          'recipe_count': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add recipe: $e');
    }
  }

  /// Get all recipes from Firestore
  Future<List<Recipe>> getAllRecipes() async {
    try {
      final querySnapshot = await _firestore
          .collection(_recipesCollection)
          .get();
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

  /// Get recipes by user ID
  Future<List<Recipe>> getRecipesByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_recipesCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final docs = querySnapshot.docs.toList();
      docs.sort((a, b) {
        final aCreated = a.data()['createdAt'];
        final bCreated = b.data()['createdAt'];
        if (aCreated is Timestamp && bCreated is Timestamp) {
          return bCreated.compareTo(aCreated);
        }
        return 0;
      });
      return docs.map((doc) => _documentToRecipe(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user recipes: $e');
    }
  }

  /// Get current user's recipes
  Future<List<Recipe>> getCurrentUserRecipes() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }
      return getRecipesByUserId(userId);
    } catch (e) {
      throw Exception('Failed to fetch current user recipes: $e');
    }
  }

  /// Get a single recipe by ID
  Future<Recipe?> getRecipeById(String recipeId) async {
    try {
      final doc = await _firestore
          .collection(_recipesCollection)
          .doc(recipeId)
          .get();
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
    required String category,
    required String imageUrl,
    required int cookTimeMinutes,
    required String author,
    String? userId,
  }) async {
    try {
      final parentRecipe = await getRecipeById(parentRecipeId);
      if (parentRecipe == null) {
        throw Exception('Parent recipe not found');
      }

      final now = DateTime.now();
      final dateStr =
          '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
      final uid = userId ?? _auth.currentUser?.uid;
      final authorName =
          author ?? _auth.currentUser?.email?.split('@')[0] ?? 'user';

      final twistData = {
        'name': twistName,
        'category': category,
        'cookTimeMinutes': cookTimeMinutes,
        'author': authorName,
        'userId': uid,
        'date': dateStr,
        'imageUrl': imageUrl,
        'rating': 0.0,
        'reviewCount': 0,
        'hasTwist': true,
        'parentRecipeId': parentRecipeId,
        'parentRecipeName': parentRecipe.name,
        'parentRecipeAuthor': parentRecipe.author,
        'reviews': [],
        'createdAt': FieldValue.serverTimestamp(),

        // Save ingredients and steps as Maps to preserve status
        'ingredients': modifiedIngredients
            .map(
              (ing) => {
                'label': ing.label,
                'status': ing.status?.name ?? 'unchanged',
              },
            )
            .toList(),

        'steps': modifiedSteps
            .map(
              (step) => {
                'text': step.text,
                'status': step.status?.name ?? 'unchanged',
              },
            )
            .toList(),
      };

      final docRef = await _firestore
          .collection(_recipesCollection)
          .add(twistData);

      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({
          'twist_count': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add twist: $e');
    }
  }

  /// Helper method to convert Firestore document to Recipe object
  Recipe _documentToRecipe(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle Ingredients (check if String or Map)
    final rawIngredients = data['ingredients'] as List<dynamic>? ?? [];
    final ingredients = rawIngredients.map((item) {
      if (item is Map) {
        return RecipeIngredient(
          label: item['label'] ?? '',
          status: IngredientStatus.values.byName(item['status'] ?? 'unchanged'),
        );
      }
      return RecipeIngredient(label: item.toString()); // Fallback for old data
    }).toList();

    // Handle Steps (check if String or Map)
    final rawSteps = data['steps'] as List<dynamic>? ?? [];
    final steps = rawSteps.map((item) {
      if (item is Map) {
        return RecipeStep(
          text: item['text'] ?? '',
          status: StepStatus.values.byName(item['status'] ?? 'unchanged'),
        );
      }
      return RecipeStep(text: item.toString()); // Fallback for old data
    }).toList();

    final reviewDocs = List<Map<String, dynamic>>.from(data['reviews'] ?? []);
    final reviews = reviewDocs
        .map(
          (reviewData) => RecipeReview(
            author: reviewData['author'] ?? 'Anonymous',
            rating: (reviewData['rating'] ?? 0).toDouble(),
            comment: reviewData['comment'] ?? '',
          ),
        )
        .toList();

    return Recipe(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      author: data['author'] ?? 'Unknown',
      userId: data['userId'],
      date: data['date'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      cookTimeMinutes: data['cookTimeMinutes'] ?? '',
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

  /// Update an existing recipe or twist in Firestore
  Future<void> updateRecipe({
    required String recipeId,
    required String name,
    required String category,
    required int cookTimeMinutes,
    required List<RecipeIngredient> ingredients,
    required List<RecipeStep> steps,
    required String imagePath,
  }) async {
    try {
      await _firestore.collection(_recipesCollection).doc(recipeId).update({
        'name': name,
        'category': category,
        'cookTimeMinutes': cookTimeMinutes,
        'imageUrl': imagePath,
        // Maps the models down to clean String lists matching your schema
        'ingredients': ingredients.map((ing) => ing.label).toList(),
        'steps': steps.map((step) => step.text).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update recipe: $e');
    }
  }

  /// Delete a recipe or twist from Firestore and decrement user statistics
  Future<void> deleteRecipe(String recipeId) async {
    try {
      // 1. Fetch the recipe first to see who owns it and check if it's a twist
      final recipeDoc = await _firestore
          .collection(_recipesCollection)
          .doc(recipeId)
          .get();

      if (!recipeDoc.exists) {
        throw Exception('Recipe not found');
      }

      final data = recipeDoc.data() as Map<String, dynamic>;
      final uid = data['userId'];
      final bool isTwist = data['hasTwist'] ?? false;

      // 2. Delete the recipe document
      await _firestore.collection(_recipesCollection).doc(recipeId).delete();

      // 3. Decrement the user's statistics safely if the user ID exists
      if (uid != null) {
        final counterField = isTwist ? 'twist_count' : 'recipe_count';
        await _firestore.collection('users').doc(uid).set({
          counterField: FieldValue.increment(-1),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to delete recipe: $e');
    }
  }
}
