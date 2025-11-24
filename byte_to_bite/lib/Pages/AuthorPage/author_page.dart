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

  @override
  void initState() {
    super.initState();
    _loadAuthorStats();
  }

  Future<void> _loadAuthorStats() async {
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
            child: StreamBuilder<QuerySnapshot>(
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
            ),
          ),
        ],
      ),
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