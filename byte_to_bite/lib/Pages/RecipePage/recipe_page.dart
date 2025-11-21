import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Recipe {
  final String name;
  final String imageUrl;
  final List<String> hashtags;
  final String author;
  double rating;
  int ratingCount;
  bool isFavorite;
  bool isBookmarked;

  Recipe({
    required this.name,
    required this.imageUrl,
    required this.hashtags,
    required this.author,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.isFavorite = false,
    this.isBookmarked = false,
  });
}

class RecipeFeedPage extends StatefulWidget {
  final String userName;
  final Function(Recipe recipe)? onToggleFavorite;
  final Function(Recipe recipe)? onToggleBookmark;
  final Set<String>? favoriteRecipeNames;
  final Set<String>? bookmarkedRecipeNames;

  const RecipeFeedPage({
    super.key, 
    this.userName = 'User',
    this.onToggleFavorite,
    this.onToggleBookmark,
    this.favoriteRecipeNames,
    this.bookmarkedRecipeNames,
  });

  @override
  State<RecipeFeedPage> createState() => _RecipeFeedPageState();
}

class _RecipeFeedPageState extends State<RecipeFeedPage> {
  String _selectedFeed = 'Featured'; 
  
  // Sample recipe data this will come from database later 
  final List<Recipe> recipes = [
    Recipe(
      name: 'Vegan Bowl',
      imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
      hashtags: ['#vegan', '#glutenfree', '#healthy', '#plantbased'],
      author: 'HealthyEats',
    ),
    Recipe(
      name: 'Grilled Chicken Salad',
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
      hashtags: ['#glutenfree', '#keto', '#lowcarb', '#protein'],
      author: 'FitMeals',
    ),
    Recipe(
      name: 'Quinoa Power Bowl',
      imageUrl: 'https://images.unsplash.com/photo-1505576399279-565b52d4ac71?w=800',
      hashtags: ['#vegan', '#glutenfree', '#vegetarian', '#healthy'],
      author: 'GreenKitchen',
    ),
    Recipe(
      name: 'Salmon with Veggies',
      imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800',
      hashtags: ['#keto', '#paleo', '#glutenfree', '#omega3'],
      author: 'SeafoodLover',
    ),
    Recipe(
      name: 'Cauliflower Pizza',
      imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800',
      hashtags: ['#glutenfree', '#lowcarb', '#keto', '#vegetarian'],
      author: 'HealthySwaps',
    ),
    Recipe(
      name: 'Green Smoothie Bowl',
      imageUrl: 'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=800',
      hashtags: ['#vegan', '#glutenfree', '#smoothie', '#breakfast'],
      author: 'MorningBoost',
    ),
    Recipe(
      name: 'Zucchini Noodles',
      imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800',
      hashtags: ['#glutenfree', '#vegan', '#lowcarb', '#paleo'],
      author: 'PastaAlternatives',
    ),
    Recipe(
      name: 'Greek Yogurt Parfait',
      imageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800',
      hashtags: ['#glutenfree', '#protein', '#breakfast', '#vegetarian'],
      author: 'YogurtLovers',
    ),
  ];

  // User submitted recipes
  final List<Recipe> userRecipes = [
    Recipe(
      name: 'Homemade Pasta Bake',
      imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800',
      hashtags: ['#pasta', '#comfort', '#homemade', '#vegetarian'],
      author: 'CookingWithLove',
    ),
    Recipe(
      name: 'Spicy Thai Curry',
      imageUrl: 'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=800',
      hashtags: ['#thai', '#spicy', '#vegan', '#curry'],
      author: 'SpiceKitchen',
    ),
    Recipe(
      name: 'Chocolate Protein Shake',
      imageUrl: 'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=800',
      hashtags: ['#protein', '#chocolate', '#shake', '#postworkout'],
      author: 'FitnessFoodie',
    ),
    Recipe(
      name: 'Avocado Toast',
      imageUrl: 'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=800',
      hashtags: ['#breakfast', '#avocado', '#healthy', '#vegetarian'],
      author: 'BrunchLover',
    ),
    Recipe(
      name: 'Beef Tacos',
      imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800',
      hashtags: ['#mexican', '#tacos', '#beef', '#dinner'],
      author: 'TacoTuesday',
    ),
  ];

  List<Recipe> get _currentRecipes {
    return _selectedFeed == 'Featured' ? recipes : userRecipes;
  }

  @override
  void initState() {
    super.initState();
    // Initialize favorites and bookmarks 
    if (widget.favoriteRecipeNames != null || widget.bookmarkedRecipeNames != null) {
      for (var recipe in recipes) {
        recipe.isFavorite = widget.favoriteRecipeNames?.contains(recipe.name) ?? false;
        recipe.isBookmarked = widget.bookmarkedRecipeNames?.contains(recipe.name) ?? false;
      }
      for (var recipe in userRecipes) {
        recipe.isFavorite = widget.favoriteRecipeNames?.contains(recipe.name) ?? false;
        recipe.isBookmarked = widget.bookmarkedRecipeNames?.contains(recipe.name) ?? false;
      }
    }
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
                            // Calculate new average rating
                            final totalRating = (recipe.rating * recipe.ratingCount) + userRating;
                            recipe.ratingCount++;
                            recipe.rating = totalRating / recipe.ratingCount;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Rated ${recipe.name} ${userRating.toInt()} stars!'),
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

  void _showFeedSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.star, color: Color(0xFF479E36)),
                title: const Text(
                  'Featured',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                trailing: _selectedFeed == 'Featured'
                    ? const Icon(Icons.check, color: Color(0xFF479E36))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedFeed = 'Featured';
                  });
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.people, color: Color(0xFF479E36)),
                title: const Text(
                  'User Recipes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                trailing: _selectedFeed == 'User Recipes'
                    ? const Icon(Icons.check, color: Color(0xFF479E36))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedFeed = 'User Recipes';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareRecipe(Recipe recipe) {
    final String shareText = '''
Check out this amazing recipe on Byte to Bite!

🍽️ ${recipe.name}
👤 By ${recipe.author}
⭐ Rating: ${recipe.ratingCount > 0 ? '${recipe.rating.toStringAsFixed(1)}/5.0 (${recipe.ratingCount} ratings)' : 'Not yet rated'}
${recipe.hashtags.join(' ')}

Download Byte to Bite to see the full recipe!
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
              const Text('Recipe details copied to clipboard!'),
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
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share to social media coming soon!'),
                    backgroundColor: Color(0xFF479E36),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF479E36),
              ),
              icon: const Icon(Icons.share),
              label: const Text('Share to Social Media'),
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
          children: [
            const Text(
              'Byte to Bite',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.restaurant, color: Colors.white, size: 24),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.white, size: 28),
            onPressed: () {
              // Add new recipe functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add new recipe coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Dropdown menu bar
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: GestureDetector(
              onTap: () {
                _showFeedSelector();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedFeed,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 24),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // Recipe feed
          Expanded(
            child: ListView.builder(
              itemCount: _currentRecipes.length,
              itemBuilder: (context, index) {
                final recipe = _currentRecipes[index];
                return _buildRecipeCard(recipe);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 0,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with author info
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF479E36),
                  child: Text(
                    recipe.author[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                const Icon(Icons.more_vert),
              ],
            ),
          ),
          // Recipe image
          Container(
            width: double.infinity,
            height: 300,
            color: Colors.grey[200],
            child: Image.network(
              recipe.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.restaurant, size: 80, color: Colors.grey),
                  ),
                );
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
            ),
          ),
          // buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 28,
                    color: recipe.isFavorite ? Colors.red : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      recipe.isFavorite = !recipe.isFavorite;
                    });
                    
                    // Call the callback to update favorites in main app
                    if (widget.onToggleFavorite != null) {
                      widget.onToggleFavorite!(recipe);
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(recipe.isFavorite ? 'Added to favorites!' : 'Removed from favorites'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 28),
                  onPressed: () {
                    // jaislen implement Comment section here 
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Comments coming soon!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.star_border, size: 28),
                  onPressed: () => _showRatingDialog(recipe),
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 28),
                  onPressed: () => _shareRecipe(recipe),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    recipe.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    size: 28,
                    color: recipe.isBookmarked ? const Color(0xFF479E36) : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      recipe.isBookmarked = !recipe.isBookmarked;
                    });
                    
                    // Call the callback to update bookmarks in main app
                    if (widget.onToggleBookmark != null) {
                      widget.onToggleBookmark!(recipe);
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(recipe.isBookmarked ? 'Recipe saved!' : 'Recipe removed from saved'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Recipe name and rating
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
                const SizedBox(height: 4),
                // Rating display
                if (recipe.ratingCount > 0)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.rating.toStringAsFixed(1)} (${recipe.ratingCount} ${recipe.ratingCount == 1 ? 'rating' : 'ratings'})',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                // Hashtags for dietary restrictions
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
}
