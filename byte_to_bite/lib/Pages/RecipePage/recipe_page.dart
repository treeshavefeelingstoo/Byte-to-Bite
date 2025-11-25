import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_recipe_page.dart';
import 'dart:io';
import 'dart:convert';

import 'package:byte_to_bite/pages/Jcode/jaislen.dart';
class Recipe {
  final String? id;
  final String name;
  final String imageUrl;
  final List<String> hashtags;
  final List<String> ingredients;
  final String author;
  double rating;
  int ratingCount;
  bool isFavorite;
  bool isBookmarked;

  // likes/dislikes state
  int likes;
  int dislikes;
  bool isLiked;
  bool isDisliked;

  // for comments
  List<Map<String, String>> comments = [];
  bool showComments = false;
  TextEditingController commentController = TextEditingController();

  Recipe({
    this.id,
    required this.name,
    required this.imageUrl,
    required this.hashtags,
    this.ingredients = const [],
    required this.author,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.isFavorite = false,
    this.isBookmarked = false,
    this.likes = 0,
    this.dislikes = 0,
    this.isLiked = false,
    this.isDisliked = false,
  });

  factory Recipe.fromMap(Map<String, dynamic> data, {String? id}) {
    return Recipe(
      id: id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      hashtags: List<String>.from(data['hashtags'] ?? []),
      ingredients: List<String>.from(data['ingredients'] ?? []),
      author: data['author'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      isFavorite: data['isFavorite'] ?? false,
      isBookmarked: data['isBookmarked'] ?? false,
      likes: data['likes'] ?? 0,
      dislikes: data['dislikes'] ?? 0,
      isLiked: data['isLiked'] ?? false,
      isDisliked: data['isDisliked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'hashtags': hashtags,
      'ingredients': ingredients,
      'author': author,
      'rating': rating,
      'ratingCount': ratingCount,
      'isFavorite': isFavorite,
      'isBookmarked': isBookmarked,
      'likes': likes,
      'dislikes': dislikes,
      'isLiked': isLiked,
      'isDisliked': isDisliked,
    };
  }
}

class RecipeFeedPage extends StatefulWidget {
  final String userName;
  final Stream<QuerySnapshot>? favoriteRecipeNamesStream;
  final Stream<QuerySnapshot>? bookmarkedRecipeNamesStream;
  final Function(Recipe)? onToggleFavorite;
  final Function(Recipe)? onToggleBookmark;

  const RecipeFeedPage({
    super.key,
    this.userName = 'User',
    this.favoriteRecipeNamesStream,
    this.bookmarkedRecipeNamesStream,
    this.onToggleFavorite,
    this.onToggleBookmark,
  });

  @override
  State<RecipeFeedPage> createState() => _RecipeFeedPageState();
}

class _RecipeFeedPageState extends State<RecipeFeedPage> {
  late Stream<Map<DateTime, List<Meal>>> mealPlanStream;

  // Featured recipes
  final List<Recipe> recipes = [
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
  ];

  // User recipes
  final List<Recipe> userRecipes = [
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
  ];

  List<Recipe> get _currentRecipes {
    return recipes;
  }

  @override
  void initState() {
    super.initState();
    _loadFavoritesAndBookmarks();
    final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    mealPlanStream = FirebaseFirestore.instance
        .collection('mealPlans')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final map = <DateTime, List<Meal>>{};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final days = (data['days'] as Map<String, dynamic>? ?? {});
            days.forEach((dateStr, mealsList) {
              final date = DateTime.parse(dateStr);
              final normalized = DateTime(date.year, date.month, date.day);
              final meals = (mealsList as List<dynamic>)
                  .map((e) => Meal.fromMap(Map<String, dynamic>.from(e)))
                  .toList();
              map[normalized] = meals;
            });
          }
          return map;
        });
  }

  }

  Future<void> _loadFavoritesAndBookmarks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();

    final bookmarkSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .get();

    final favNames = favSnapshot.docs.map((doc) => doc['name'] as String).toSet();
    final bookmarkNames = bookmarkSnapshot.docs.map((doc) => doc['name'] as String).toSet();

    setState(() {
      for (var recipe in recipes) {
        recipe.isFavorite = favNames.contains(recipe.name);
        recipe.isBookmarked = bookmarkNames.contains(recipe.name);
      }
      for (var recipe in userRecipes) {
        recipe.isFavorite = favNames.contains(recipe.name);
        recipe.isBookmarked = bookmarkNames.contains(recipe.name);
      }
    });
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(recipe.name);

    final snapshot = await docRef.get();
    if (snapshot.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'name': recipe.name,
        'imageUrl': recipe.imageUrl,
        'hashtags': recipe.hashtags,
        'ingredients': recipe.ingredients,
        'author': recipe.author,
      });
    }
  }

  Future<void> _toggleBookmark(Recipe recipe) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .doc(recipe.name);

    final snapshot = await docRef.get();
    if (snapshot.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'name': recipe.name,
        'imageUrl': recipe.imageUrl,
        'hashtags': recipe.hashtags,
        'ingredients': recipe.ingredients,
        'author': recipe.author,
      });
    }
  }

  Widget _buildRecipeImage(String imageUrl) {
    // Check if imageUrl is a local file path
    if (imageUrl.startsWith('/') || imageUrl.contains('\\')) {
      if (kIsWeb) {
        // On web, treat local paths as network URLs
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      } else {
        // On mobile/desktop, use File
        final file = File(imageUrl);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage();
            },
          );
        }
      }
    }
    
    // Otherwise treat as network URL
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholderImage();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            color: const Color(0xFF479E36),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.restaurant, size: 60, color: Colors.grey),
      ),
    );
  }



  void _showRatingDialog(Recipe recipe) {
    double userRating = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Rate ${recipe.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tap a star to rate this recipe:'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < userRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            userRating = (index + 1).toDouble();
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: userRating > 0
                      ? () {
                          setState(() {
                            final totalRating =
                                (recipe.rating * recipe.ratingCount) + userRating;
                            recipe.ratingCount++;
                            recipe.rating = totalRating / recipe.ratingCount;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Rated ${recipe.name} ${userRating.toInt()} stars'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF479E36),
                  ),
                  child: const Text('Submit Rating'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showIngredientsDialog(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IngredientSubstitutionPage(recipe: recipe),
      ),
    );
  }

  void _shareRecipe(Recipe recipe) {
    final String shareText = '''
Check out this recipe on Byte to Bite

${recipe.name}
By ${recipe.author}
Rating: ${recipe.ratingCount > 0 ? '${recipe.rating.toStringAsFixed(1)}/5.0 (${recipe.ratingCount} ratings)' : 'Not yet rated'}
${recipe.hashtags.join(' ')}

Download Byte to Bite to see the full recipe.
''';

    Clipboard.setData(ClipboardData(text: shareText));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Share Recipe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('The recipe details have been copied to your clipboard.'),
              const SizedBox(height: 20),
              Text(
                shareText,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share to social media coming soon'),
                    backgroundColor: Color(0xFF479E36),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF479E36),
              ),
              child: const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF479E36),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: const [
            Text(
              'Byte to Bite',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.restaurant, color: Colors.white, size: 24),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.white, size: 28),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddRecipePage(),
                ),
              );
              
              // Refresh the feed if a recipe was added
              if (result == true) {
                setState(() {
                  // This will trigger a rebuild and refresh the recipes
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _currentRecipes.length,
              itemBuilder: (context, index) {
                final recipe = _currentRecipes[index];
                return _buildRecipeCard(recipe, {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe, Map<DateTime, List<Meal>> mealPlan) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 0,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with author info + rating + menu
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF479E36),
                  child: Text(
                    recipe.author.isNotEmpty ? recipe.author[0] : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  recipe.author,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),

                // Rating button moved to top
                IconButton(
                  icon: const Icon(Icons.star_border, size: 28),
                  onPressed: () => _showRatingDialog(recipe),
                ),

                // 3-dot menu with Share
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'share') {
                      _shareRecipe(recipe);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'share',
                      child: Row(
                        children: const [
                          Icon(Icons.share, color: Colors.black54),
                          SizedBox(width: 10),
                          Text("Share"),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ),

          // Recipe image
          Container(
            width: double.infinity,
            height: 300,
            color: Colors.grey[200],
            child: _buildRecipeImage(recipe.imageUrl),
          ),

          // Buttons Row (favorites, likes, dislikes, comments, bookmark)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                // Favorite
                IconButton(
                  icon: Icon(
                    recipe.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 28,
                    color: recipe.isFavorite ? Colors.red : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      recipe.isFavorite = !recipe.isFavorite;
                    });

                    _toggleFavorite(recipe);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          recipe.isFavorite
                              ? 'Added to favorites'
                              : 'Removed from favorites',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),

                // Like button + count
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.thumb_up,
                        color: recipe.isLiked
                            ? const Color.fromARGB(255, 7, 118, 7)
                            : Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          if (recipe.isLiked) {
                            recipe.isLiked = false;
                            if (recipe.likes > 0) recipe.likes--;
                          } else {
                            recipe.isLiked = true;
                            recipe.likes++;
                            if (recipe.isDisliked) {
                              recipe.isDisliked = false;
                              if (recipe.dislikes > 0) recipe.dislikes--;
                            }
                          }
                        });
                      },
                    ),
                    Text(recipe.likes.toString()),
                  ],
                ),

                // Dislike button + count
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.thumb_down,
                        color: recipe.isDisliked
                            ? const Color.fromARGB(255, 7, 118, 7)
                            : Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          if (recipe.isDisliked) {
                            recipe.isDisliked = false;
                            if (recipe.dislikes > 0) recipe.dislikes--;
                          } else {
                            recipe.isDisliked = true;
                            recipe.dislikes++;
                            if (recipe.isLiked) {
                              recipe.isLiked = false;
                              if (recipe.likes > 0) recipe.likes--;
                            }
                          }
                        });
                      },
                    ),
                    Text(recipe.dislikes.toString()),
                  ],
                ),

                // Comment button
                IconButton(
                  icon: Icon(
                    recipe.showComments
                        ? Icons.chat_bubble
                        : Icons.chat_bubble_outline,
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      recipe.showComments = !recipe.showComments;
                    });
                  },
                ),

                const Spacer(),

                // Bookmark
                IconButton(
                  icon: Icon(
                    recipe.isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    size: 28,
                    color: recipe.isBookmarked
                        ? const Color(0xFF479E36)
                        : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      recipe.isBookmarked = !recipe.isBookmarked;
                    });

                    _toggleBookmark(recipe);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          recipe.isBookmarked
                              ? 'Recipe saved'
                              : 'Recipe removed from saved',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Inline Comments
          if (recipe.showComments) _buildCommentsSection(recipe),

          // Recipe name, rating, hashtags
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 8),

                // Ingredients button
                if (recipe.ingredients.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showIngredientsDialog(recipe),
                    child: const Text(
                      'Ingredients',
                      style: TextStyle(
                        color: Color(0xFF479E36),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF479E36),
                      ),
                    ),
                  ),

                const SizedBox(height: 4),

                if (recipe.ratingCount > 0)
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.rating.toStringAsFixed(1)} (${recipe.ratingCount} ratings)',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: recipe.hashtags.map((tag) {
                    return Text(
                      tag,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// comments section
  Widget _buildCommentsSection(Recipe recipe) {
    final controller = recipe.commentController;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Comments",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          if (recipe.comments.isEmpty)
            const Text("No comments yet.",
                style: TextStyle(color: Colors.grey)),

          if (recipe.comments.isNotEmpty)
            Column(
              children: recipe.comments.map((c) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF479E36),
                        child: Text(
                          c["user"]![0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c["text"]!)),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "Write a comment...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF479E36)),
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;

                  setState(() {
                    recipe.comments.add({
                      "user": widget.userName,
                      "text": text,
                    });
                  });

                  controller.clear();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Ingredient Substitution Page
class IngredientSubstitutionPage extends StatefulWidget {
  final Recipe recipe;

  const IngredientSubstitutionPage({super.key, required this.recipe});

  @override
  State<IngredientSubstitutionPage> createState() => _IngredientSubstitutionPageState();
}

class _IngredientSubstitutionPageState extends State<IngredientSubstitutionPage> {
  late List<String> modifiedIngredients;
  final Map<int, String> substitutions = {};
  late List<String> originalIngredients;

  // Common ingredient substitutions
  final Map<String, List<String>> substitutionOptions = {
    'butter': ['margarine', 'coconut oil', 'olive oil', 'applesauce'],
    'milk': ['almond milk', 'soy milk', 'oat milk', 'coconut milk'],
    'eggs': ['flax eggs', 'chia eggs', 'applesauce', 'mashed banana'],
    'flour': ['almond flour', 'coconut flour', 'whole wheat flour', 'gluten-free flour'],
    'sugar': ['honey', 'maple syrup', 'stevia', 'coconut sugar'],
    'cream': ['coconut cream', 'cashew cream', 'greek yogurt'],
    'cheese': ['nutritional yeast', 'cashew cheese', 'vegan cheese'],
    'chicken': ['tofu', 'tempeh', 'seitan', 'chickpeas'],
    'beef': ['ground turkey', 'lentils', 'mushrooms', 'plant-based meat'],
    'oil': ['butter', 'ghee', 'avocado oil', 'cooking spray'],
    'sour cream': ['greek yogurt', 'cashew cream', 'coconut yogurt'],
    'yogurt': ['sour cream', 'buttermilk', 'coconut yogurt'],
    'breadcrumbs': ['panko', 'crushed crackers', 'oats', 'almond flour'],
    'pasta': ['zucchini noodles', 'whole wheat pasta', 'rice noodles', 'chickpea pasta'],
    'rice': ['cauliflower rice', 'quinoa', 'couscous', 'bulgur'],
  };

  @override
  void initState() {
    super.initState();
    originalIngredients = List.from(widget.recipe.ingredients);
    modifiedIngredients = List.from(widget.recipe.ingredients);
    _loadSavedSubstitutions();
  }

  // Load saved substitutions from SharedPreferences
  Future<void> _loadSavedSubstitutions() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'substitutions_${widget.recipe.name}';
    final savedData = prefs.getString(key);
    
    if (savedData != null) {
      try {
        final Map<String, dynamic> data = json.decode(savedData);
        setState(() {
          // Load substitutions
          final savedSubs = data['substitutions'] as Map<String, dynamic>?;
          if (savedSubs != null) {
            savedSubs.forEach((key, value) {
              substitutions[int.parse(key)] = value.toString();
            });
          }
          
          // Load modified ingredients
          final savedIngredients = data['modifiedIngredients'] as List<dynamic>?;
          if (savedIngredients != null) {
            modifiedIngredients = List<String>.from(savedIngredients);
          }
        });
      } catch (e) {
        // If there's an error loading, just use the original ingredients
        print('Error loading substitutions: $e');
      }
    }
  }

  // Save substitutions to SharedPreferences
  Future<void> _saveSubstitutions() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'substitutions_${widget.recipe.name}';
    
    if (substitutions.isEmpty) {
      // If no substitutions, remove the saved data
      await prefs.remove(key);
    } else {
      final data = {
        'substitutions': substitutions.map((k, v) => MapEntry(k.toString(), v)),
        'modifiedIngredients': modifiedIngredients,
      };
      await prefs.setString(key, json.encode(data));
    }
  }

  List<String> _getSuggestedSubstitutions(String ingredient) {
    final lowerIngredient = ingredient.toLowerCase();
    
    for (var entry in substitutionOptions.entries) {
      if (lowerIngredient.contains(entry.key)) {
        return entry.value;
      }
    }
    return [];
  }

  void _showSubstitutionDialog(int index, String originalIngredient) {
    final suggestions = _getSuggestedSubstitutions(originalIngredient);
    final TextEditingController customController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Substitute Ingredient',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF479E36),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Original: $originalIngredient',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                if (suggestions.isNotEmpty) ...[
                  const Text(
                    'Suggested Substitutions:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...suggestions.map((substitution) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(
                        Icons.swap_horiz,
                        color: Color(0xFF479E36),
                        size: 20,
                      ),
                      title: Text(substitution),
                      onTap: () {
                        _applySubstitution(index, originalIngredient, substitution);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                  const Divider(height: 24),
                ],
                const Text(
                  'Custom Substitution:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: customController,
                  decoration: const InputDecoration(
                    hintText: 'Enter custom substitute...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (customController.text.isNotEmpty) {
                  _applySubstitution(index, originalIngredient, customController.text);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF479E36),
              ),
              child: const Text(
                'Apply Custom',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _applySubstitution(int index, String original, String substitute) {
    setState(() {
      // replace the ingredient
      final originalLower = original.toLowerCase();
      String modified = original;

      // Find the key ingredient and replace it
      for (var key in substitutionOptions.keys) {
        if (originalLower.contains(key)) {
          final regex = RegExp(key, caseSensitive: false);
          modified = original.replaceFirst(regex, substitute);
          break;
        }
      }

      // If no pattern match, do a simple replacement
      if (modified == original) {
        modified = substitute;
      }

      modifiedIngredients[index] = modified;
      substitutions[index] = substitute;
    });

    // Auto-save after applying substitution
    _saveSubstitutions();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Substituted with $substitute'),
        backgroundColor: const Color(0xFF479E36),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetIngredient(int index) {
    setState(() {
      modifiedIngredients[index] = originalIngredients[index];
      substitutions.remove(index);
    });

    // Auto-save after resetting ingredient
    _saveSubstitutions();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ingredient reset to original'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetAllIngredients() {
    setState(() {
      modifiedIngredients = List.from(originalIngredients);
      substitutions.clear();
    });

    // Auto-save (clear) after resetting all ingredients
    _saveSubstitutions();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All ingredients reset to original'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveModifiedRecipe() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Save Modified Recipe',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF479E36),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Modified Ingredients:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: modifiedIngredients.map((ingredient) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• $ingredient',
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                try {
                  // Save modified recipe to user's saved recipes with modifications
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('modified_recipes')
                      .doc(widget.recipe.name)
                      .set({
                    'originalRecipeName': widget.recipe.name,
                    'originalIngredients': widget.recipe.ingredients,
                    'modifiedIngredients': modifiedIngredients,
                    'substitutions': substitutions.map((k, v) => MapEntry(k.toString(), v)),
                    'imageUrl': widget.recipe.imageUrl,
                    'author': widget.recipe.author,
                    'hashtags': widget.recipe.hashtags,
                    'modifiedAt': FieldValue.serverTimestamp(),
                  });

                  if (!mounted) return;
                  Navigator.pop(context);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Modified recipe saved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving recipe: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF479E36),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modify Ingredients'),
        backgroundColor: const Color(0xFF479E36),
        foregroundColor: Colors.white,
        actions: [
          if (substitutions.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.restore, color: Colors.white, size: 20),
              label: const Text(
                'Original Recipe',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text(
                        'Revert to Original Recipe',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF479E36),
                        ),
                      ),
                      content: Text(
                        'This will remove all ${substitutions.length} substitution${substitutions.length > 1 ? 's' : ''} and restore the original recipe. This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _resetAllIngredients();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text(
                            'Revert to Original',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Modified Recipe',
            onPressed: substitutions.isEmpty ? null : _saveModifiedRecipe,
          ),
        ],
      ),
      body: Column(
        children: [
          // Recipe header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipe.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF479E36),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By ${widget.recipe.author}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (substitutions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF479E36),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${substitutions.length} substitution${substitutions.length > 1 ? 's' : ''} applied',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue[50],
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap any ingredient to substitute it',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),

          // Ingredients list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: modifiedIngredients.length,
              itemBuilder: (context, index) {
                final ingredient = modifiedIngredients[index];
                final isModified = substitutions.containsKey(index);
                final originalIngredient = originalIngredients[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isModified ? 3 : 1,
                  color: isModified ? Colors.green[50] : Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isModified ? const Color(0xFF479E36) : Colors.grey[300],
                      child: Icon(
                        isModified ? Icons.check : Icons.circle,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      ingredient,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isModified ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: isModified
                        ? Text(
                            'Original: $originalIngredient',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              decoration: TextDecoration.lineThrough,
                            ),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isModified)
                          IconButton(
                            icon: const Icon(Icons.undo, color: Colors.orange),
                            tooltip: 'Reset to original',
                            onPressed: () => _resetIngredient(index),
                          ),
                        IconButton(
                          icon: Icon(
                            isModified ? Icons.edit : Icons.swap_horiz,
                            color: const Color(0xFF479E36),
                          ),
                          tooltip: isModified ? 'Change substitution' : 'Substitute',
                          onPressed: () => _showSubstitutionDialog(index, originalIngredient),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
