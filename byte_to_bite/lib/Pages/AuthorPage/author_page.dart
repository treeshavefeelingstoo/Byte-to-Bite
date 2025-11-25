import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../RecipePage/recipe_page.dart';

class AuthorPage extends StatefulWidget {
  final String authorName;
  final String? authorId; // Firebase user ID of the author

  const AuthorPage({
    super.key,
    required this.authorName,
    this.authorId,
  });

  @override
  State<AuthorPage> createState() => _AuthorProfilePageState();
}

class _AuthorProfilePageState extends State<AuthorPage> {
  int recipeCount = 0;
  int totalLikes = 0;
  double averageRating = 0.0;
  
  // Hardcoded recipes for each author
  final Map<String, List<Recipe>> _authorRecipes = {
    'HealthyEats': [
      Recipe(
        name: 'Vegan Bowl',
        imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
        hashtags: ['#vegan', '#glutenfree', '#healthy', '#plantbased'],
        ingredients: [
          'Quinoa',
          'Mixed greens',
          'Cherry tomatoes',
          'Avocado',
          'Chickpeas',
          'Lemon tahini dressing',
          'Sunflower seeds',
        ],
        author: 'HealthyEats',
      ),
      Recipe(
        name: 'Green Smoothie Bowl',
        imageUrl: 'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=800',
        hashtags: ['#vegan', '#glutenfree', '#smoothie', '#breakfast'],
        ingredients: [
          'Frozen banana',
          'Spinach',
          'Almond milk',
          'Chia seeds',
          'Fresh berries',
          'Granola',
          'Coconut flakes',
        ],
        author: 'HealthyEats',
      ),
      Recipe(
        name: 'Quinoa Power Bowl',
        imageUrl: 'https://images.unsplash.com/photo-1505576399279-565b52d4ac71?w=800',
        hashtags: ['#vegan', '#glutenfree', '#vegetarian', '#healthy'],
        ingredients: [
          'Cooked quinoa',
          'Roasted sweet potato',
          'Kale',
          'Chickpeas',
          'Tahini dressing',
          'Hemp seeds',
          'Lemon juice',
        ],
        author: 'HealthyEats',
      ),
    ],
    'FitMeals': [
      Recipe(
        name: 'Grilled Chicken Salad',
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
        hashtags: ['#glutenfree', '#keto', '#lowcarb', '#protein'],
        ingredients: [
          'Grilled chicken breast',
          'Romaine lettuce',
          'Cherry tomatoes',
          'Cucumber',
          'Red onion',
          'Feta cheese',
          'Olive oil and lemon dressing',
        ],
        author: 'FitMeals',
      ),
      Recipe(
        name: 'Salmon with Veggies',
        imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800',
        hashtags: ['#keto', '#paleo', '#glutenfree', '#omega3'],
        ingredients: [
          'Fresh salmon fillet',
          'Asparagus',
          'Bell peppers',
          'Olive oil',
          'Garlic',
          'Lemon',
          'Fresh herbs',
        ],
        author: 'FitMeals',
      ),
      Recipe(
        name: 'Greek Yogurt Parfait',
        imageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800',
        hashtags: ['#glutenfree', '#protein', '#breakfast', '#vegetarian'],
        ingredients: [
          'Greek yogurt',
          'Fresh berries',
          'Honey',
          'Granola',
          'Sliced almonds',
          'Chia seeds',
          'Mint leaves',
        ],
        author: 'FitMeals',
      ),
    ],
    'GreenKitchen': [
      Recipe(
        name: 'Quinoa Power Bowl',
        imageUrl: 'https://images.unsplash.com/photo-1505576399279-565b52d4ac71?w=800',
        hashtags: ['#vegan', '#glutenfree', '#vegetarian', '#healthy'],
        ingredients: [
          'Cooked quinoa',
          'Roasted sweet potato',
          'Kale',
          'Chickpeas',
          'Tahini dressing',
          'Hemp seeds',
          'Lemon juice',
        ],
        author: 'GreenKitchen',
      ),
      Recipe(
        name: 'Zucchini Noodles',
        imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800',
        hashtags: ['#glutenfree', '#vegan', '#lowcarb', '#paleo'],
        ingredients: [
          'Zucchini (spiralized)',
          'Cherry tomatoes',
          'Garlic',
          'Olive oil',
          'Fresh basil',
          'Pine nuts',
          'Nutritional yeast',
        ],
        author: 'GreenKitchen',
      ),
    ],
    'SeafoodLover': [
      Recipe(
        name: 'Salmon with Veggies',
        imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800',
        hashtags: ['#keto', '#paleo', '#glutenfree', '#omega3'],
        ingredients: [
          'Fresh salmon fillet',
          'Asparagus',
          'Bell peppers',
          'Olive oil',
          'Garlic',
          'Lemon',
          'Fresh herbs',
        ],
        author: 'SeafoodLover',
      ),
    ],
    'HealthySwaps': [
      Recipe(
        name: 'Cauliflower Pizza',
        imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800',
        hashtags: ['#glutenfree', '#lowcarb', '#keto', '#vegetarian'],
        ingredients: [
          'Cauliflower rice',
          'Mozzarella cheese',
          'Egg',
          'Tomato sauce',
          'Fresh basil',
          'Cherry tomatoes',
          'Italian seasoning',
        ],
        author: 'HealthySwaps',
      ),
    ],
    'MorningBoost': [
      Recipe(
        name: 'Green Smoothie Bowl',
        imageUrl: 'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=800',
        hashtags: ['#vegan', '#glutenfree', '#smoothie', '#breakfast'],
        ingredients: [
          'Frozen banana',
          'Spinach',
          'Almond milk',
          'Chia seeds',
          'Fresh berries',
          'Granola',
          'Coconut flakes',
        ],
        author: 'MorningBoost',
      ),
    ],
    'PastaAlternatives': [
      Recipe(
        name: 'Zucchini Noodles',
        imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800',
        hashtags: ['#glutenfree', '#vegan', '#lowcarb', '#paleo'],
        ingredients: [
          'Zucchini (spiralized)',
          'Cherry tomatoes',
          'Garlic',
          'Olive oil',
          'Fresh basil',
          'Pine nuts',
          'Nutritional yeast',
        ],
        author: 'PastaAlternatives',
      ),
    ],
    'YogurtLovers': [
      Recipe(
        name: 'Greek Yogurt Parfait',
        imageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800',
        hashtags: ['#glutenfree', '#protein', '#breakfast', '#vegetarian'],
        ingredients: [
          'Greek yogurt',
          'Fresh berries',
          'Honey',
          'Granola',
          'Sliced almonds',
          'Chia seeds',
          'Mint leaves',
        ],
        author: 'YogurtLovers',
      ),
    ],
    'CookingWithLove': [
      Recipe(
        name: 'Homemade Pasta Bake',
        imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800',
        hashtags: ['#pasta', '#comfort', '#homemade', '#vegetarian'],
        ingredients: [
          'Pasta',
          'Marinara sauce',
          'Mozzarella cheese',
          'Ricotta cheese',
          'Parmesan cheese',
          'Italian herbs',
          'Garlic',
        ],
        author: 'CookingWithLove',
      ),
    ],
    'SpiceKitchen': [
      Recipe(
        name: 'Spicy Thai Curry',
        imageUrl: 'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=800',
        hashtags: ['#thai', '#spicy', '#vegan', '#curry'],
        ingredients: [
          'Coconut milk',
          'Red curry paste',
          'Tofu',
          'Bell peppers',
          'Bamboo shoots',
          'Thai basil',
          'Lime juice',
        ],
        author: 'SpiceKitchen',
      ),
    ],
    'FitnessFoodie': [
      Recipe(
        name: 'Chocolate Protein Shake',
        imageUrl: 'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=800',
        hashtags: ['#protein', '#chocolate', '#shake', '#postworkout'],
        ingredients: [
          'Protein powder',
          'Banana',
          'Almond milk',
          'Cocoa powder',
          'Peanut butter',
          'Ice cubes',
          'Honey',
        ],
        author: 'FitnessFoodie',
      ),
    ],
    'BrunchLover': [
      Recipe(
        name: 'Avocado Toast',
        imageUrl: 'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=800',
        hashtags: ['#breakfast', '#avocado', '#healthy', '#vegetarian'],
        ingredients: [
          'Whole grain bread',
          'Ripe avocado',
          'Lemon juice',
          'Cherry tomatoes',
          'Red pepper flakes',
          'Sea salt',
          'Olive oil',
        ],
        author: 'BrunchLover',
      ),
    ],
    'TacoTuesday': [
      Recipe(
        name: 'Beef Tacos',
        imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800',
        hashtags: ['#mexican', '#tacos', '#beef', '#dinner'],
        ingredients: [
          'Ground beef',
          'Taco shells',
          'Lettuce',
          'Tomatoes',
          'Cheese',
          'Sour cream',
          'Taco seasoning',
        ],
        author: 'TacoTuesday',
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadAuthorStats();
  }

  Future<void> _loadAuthorStats() async {
    // For hardcoded authors, use hardcoded recipes
    if (_authorRecipes.containsKey(widget.authorName)) {
      final recipes = _authorRecipes[widget.authorName]!;
      setState(() {
        recipeCount = recipes.length;
        totalLikes = 0; // Can be adjusted if needed
        averageRating = 0.0; // Can be adjusted if needed
      });
      return;
    }
    
    // For other authors, try Firebase
    try {
      // Query all users to find recipes by this author name
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      
      int count = 0;
      int likes = 0;
      double totalRating = 0.0;
      int ratedRecipes = 0;

      for (var userDoc in usersSnapshot.docs) {
        final recipesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('recipes')
            .where('author', isEqualTo: widget.authorName)
            .where('isArchived', isEqualTo: false)
            .get();

        count += recipesSnapshot.docs.length;

        for (var recipeDoc in recipesSnapshot.docs) {
          final data = recipeDoc.data();
          likes += (data['likes'] ?? 0) as int;
          
          if ((data['ratingCount'] ?? 0) > 0) {
            totalRating += (data['rating'] ?? 0.0).toDouble();
            ratedRecipes++;
          }
        }
      }

      setState(() {
        recipeCount = count;
        totalLikes = likes;
        averageRating = ratedRecipes > 0 ? totalRating / ratedRecipes : 0.0;
      });
    } catch (e) {
      print('Error loading author stats: $e');
    }
  }

  // Helper method to display recipe images from local storage or network
  Widget _buildRecipeImage(String imageUrl) {
    if (imageUrl.startsWith('/') || (imageUrl.length > 2 && imageUrl[1] == ':')) {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        );
      }
    }
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child: Text(
          '🍽️',
          style: TextStyle(fontSize: 40),
        ),
      ),
    );
  }

  void _showRecipeDetail(Recipe recipe) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 250,
                child: _buildRecipeImage(recipe.imageUrl),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (recipe.hashtags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: recipe.hashtags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            backgroundColor: Colors.green[100],
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = FirebaseAuth.instance.currentUser != null &&
        widget.authorId == FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.authorName}\'s Profile'),
        backgroundColor: const Color(0xFF479E36),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          // Profile Avatar
          CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFF479E36),
            child: Text(
              widget.authorName.isNotEmpty ? widget.authorName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Author Name
          Text(
            widget.authorName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          if (isCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'You',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 20),
          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('Recipes', recipeCount.toString()),
                _buildStatColumn('Likes', totalLikes.toString()),
                _buildStatColumn('Avg Rating', averageRating.toStringAsFixed(1)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Recipes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Recipes Grid
          Expanded(
            child: _buildRecipesGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipesGrid() {
    // Check if this is a hardcoded author
    if (_authorRecipes.containsKey(widget.authorName)) {
      final recipes = _authorRecipes[widget.authorName]!;
      
      if (recipes.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No recipes yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }
      
      return GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return GestureDetector(
            onTap: () => _showRecipeDetail(recipe),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
              ),
              child: _buildRecipeImage(recipe.imageUrl),
            ),
          );
        },
      );
    }
    
    // For non-hardcoded authors, use Firebase StreamBuilder
    return StreamBuilder<QuerySnapshot>(
      stream: _getAuthorRecipesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No recipes yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final recipes = snapshot.data!.docs
            .map((doc) => Recipe.fromMap(
                  doc.data() as Map<String, dynamic>,
                  id: doc.id,
                ))
            .toList();

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return GestureDetector(
              onTap: () => _showRecipeDetail(recipe),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                ),
                child: _buildRecipeImage(recipe.imageUrl),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _getAuthorRecipesStream() {
    // This is a complex query - we need to search across all users
    // For now, we'll search through the current user's collection if it's their profile
    // or all users for other authors
    if (widget.authorId != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(widget.authorId)
          .collection('recipes')
          .where('isArchived', isEqualTo: false)
          .snapshots();
    } else {
      // Fallback: search the current user if logged in
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        return FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('recipes')
            .where('author', isEqualTo: widget.authorName)
            .where('isArchived', isEqualTo: false)
            .snapshots();
      }
    }
    
    // Return empty stream if no user
    return const Stream.empty();
  }
}