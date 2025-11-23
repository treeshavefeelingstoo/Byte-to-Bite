import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:byte_to_bite/Pages/Welcome/welcome_page.dart';
import 'package:byte_to_bite/constants.dart';

import 'package:byte_to_bite/pages/Jcode/jaislen.dart';

import 'package:byte_to_bite/Pages/HomePage/home_page.dart';
import 'package:byte_to_bite/Pages/RecipePage/recipe_page.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Welcome to Byte to Bite',
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: const Color(0xFFB8EEB0),
      ),
      home: WelcomePageWrapper(),
       );
  }
}

class WelcomePageWrapper extends StatelessWidget {
  const WelcomePageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return WelcomePage(
      onContinue: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DietaryApp(userName: 'Guest')),
        );
      },
    );
  }
}


class DietaryApp extends StatefulWidget {
  final String userName;
  final Set<String>? initialExclusions;
  final int? initialIndex;

  const DietaryApp({
    super.key,
    required this.userName,
    this.initialExclusions,
    this.initialIndex,
  });


  @override
  State<DietaryApp> createState() => _DietaryAppState();
}

class _DietaryAppState extends State<DietaryApp> {
  int _selectedIndex = 0;
  Set<String> excludedIngredients = {};

  final Map<DateTime, List<Meal>> _mealPlan = {};
  final Map<DateTime, Set<String>> _groceriesByWeek = {};
  final Map<String, bool> _checkedGroceries = {};
  Set<Meal> _savedRecipes = {};


  List<Recipe> _favoriteRecipes = [];
  List<Recipe> _bookmarkedRecipes = [];

  

  @override
  void initState() {
  super.initState();
  _selectedIndex = widget.initialIndex ?? 0;
  if (widget.initialExclusions != null) {
    excludedIngredients = widget.initialExclusions!;
    _saveExclusions(excludedIngredients); 
  } else {
    _loadExclusions(); 
  }
}


  Future<File> getLocalFile() async {
    final directory = Directory.systemTemp; 
    return File('${directory.path}/excluded_ingredients.json');
  }

  Future<void> _saveExclusions(Set<String> exclusions) async {
    final file = await getLocalFile();
    final jsonString = jsonEncode(exclusions.toList());
    await file.writeAsString(jsonString);
  }

  Future<void> _loadExclusions() async 
  {
    final file = await getLocalFile();
    if (await file.exists()) 
    {
      final jsonString = await file.readAsString();
      final List<dynamic> decoded = jsonDecode(jsonString);
      setState(() 
      {
        excludedIngredients = decoded.cast<String>().toSet();
      });
    }
  }

     void _toggleGroceryItem(DateTime weekStart, String item) {
      final key = '${weekStart.millisecondsSinceEpoch}_$item';
      setState(() {
        _checkedGroceries[key] = !(_checkedGroceries[key] ?? false);
      });
    }

    void _handleWeekGroceriesChanged(DateTime weekStart, Set<String> items) {
      setState(() {
        _groceriesByWeek[weekStart] = items;
      });
    }


    void _deleteWeek(DateTime weekStart) {
      setState(() {
        _checkedGroceries.removeWhere((key, _) =>
          key.startsWith('${weekStart.millisecondsSinceEpoch}_'));
        _groceriesByWeek.remove(weekStart);
        final weekEnd = weekStart.add(const Duration(days: 7));
        _mealPlan.removeWhere((date, _) =>
          date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          date.isBefore(weekEnd));
      });
    }


    void _updateExclusions(Set<String> exclusions) {
      setState(() {
        excludedIngredients = exclusions;
      });
      _saveExclusions(exclusions);
    }

    Set<String> _getWeekGroceries(DateTime weekStart) {
      return _groceriesByWeek[weekStart] ?? <String>{};
    }

    Future<void> _toggleSaveRecipe(Meal meal) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('saved')
      .doc(meal.name); // replace with meal.id if available

  final snapshot = await docRef.get();

  if (snapshot.exists) {
    await docRef.delete();
    setState(() {
      _savedRecipes?.remove(meal);
    });
  } else {
    await docRef.set({
      'name': meal.name,
      'ingredients': meal.ingredients.map((i) => i.toString()).toList(),
      'restrictions': meal.restrictions.map((r) => r.toString()).toList(),
      'color': meal.color.value,
      'icon': meal.icon.codePoint,
    });
    setState(() {
      _savedRecipes?.add(meal);
    });
  }
}



    Future<void> _addMealToFavorites(Meal meal) async  {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Map meal colors to image URLs 
      final Map<Color, String> colorToImage = {
        Colors.green: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
        Colors.orange: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
        Colors.blue: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400',
        Colors.purple: 'https://images.unsplash.com/photo-1505576399279-565b52d4ac71?w=400',
        Colors.brown: 'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=400',
        Colors.red: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400',
        Colors.teal: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
        Colors.amber: 'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=400',
      };

      final Map<String, dynamic> mealMap = {
        'name': meal.name,
        'imageUrl': colorToImage[meal.color] ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
        'hashtags': meal.restrictions.map((r) => '#${r.toLowerCase().replaceAll(' ', '')}').toList(),
        'author': 'Meal Planner',
      };

      await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('favorites')
      .doc(meal.name) // use recipe name or a unique ID
      .set(mealMap);

    }

    Future<void> _toggleFavoriteRecipe(Recipe recipe) async {
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
      'author': recipe.author,
    });
  }
}

Future<void> _toggleBookmarkRecipe(Recipe recipe) async {
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
      'author': recipe.author,
    });
  }
}




  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(
        mealPlan: _mealPlan as Map<DateTime, List<Meal>>?,
        onWeekGroceriesChanged: _handleWeekGroceriesChanged,
        getWeekGroceries: _getWeekGroceries,
        excludedIngredients: excludedIngredients,
        userName: widget.userName,
      ),
      RecipeFeedPage(
        userName: widget.userName,
        onToggleFavorite: _toggleFavoriteRecipe,
        onToggleBookmark: _toggleBookmarkRecipe,
        favoriteRecipeNamesStream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('favorites')
            .snapshots(),
        bookmarkedRecipeNamesStream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('bookmarks')
            .snapshots(),
      ),
      AllergySelectorScreen(
        onRestrictionsChanged: _updateExclusions,
        initialSelections: excludedIngredients,
      ),
    MealPlannerPage(
      excludedIngredients: excludedIngredients,
      savedRecipes: _savedRecipes,
      onToggleSaveRecipe: _toggleSaveRecipe,
    ),
    GroceryPage(
      onBackToMealPrep: () => setState(() => _selectedIndex = 3),
    ),

      ProfilePage(
        userName: widget.userName,
        favoriteRecipes: _favoriteRecipes,
        bookmarkedRecipes: _bookmarkedRecipes,
      ),

    ];

      return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.green[700], 
        primaryColor: Colors.white,     
      ),
      child: Scaffold(
        body: pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Recipes'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restrictions'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Meal Prep'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Groceries'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class DietaryRestrictionsSetupPage extends StatefulWidget {
  final String userName;

  const DietaryRestrictionsSetupPage({super.key, required this.userName});

  @override
  State<DietaryRestrictionsSetupPage> createState() => _DietaryRestrictionsSetupPageState();
}

class _DietaryRestrictionsSetupPageState extends State<DietaryRestrictionsSetupPage> {
  Set<String> selectedRestrictions = {};

  void _saveAndContinue() {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => DietaryApp(
        userName: widget.userName,
        initialExclusions: selectedRestrictions,
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Dietary Restrictions"),
        backgroundColor: const Color(0xFF5aa454),
        automaticallyImplyLeading: false,
      ),
      body: AllergySelectorScreen(
        onRestrictionsChanged: (restrictions) {
          setState(() {
            selectedRestrictions = restrictions;
          });
        },
        initialSelections: selectedRestrictions,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAndContinue,
        backgroundColor: const Color(0xFF5aa454),
        icon: const Icon(Icons.check),
        label: const Text('Continue'),
      ),
    );
  }
}

class AllergySelectorScreen extends StatefulWidget {
  final void Function(Set<String>) onRestrictionsChanged;
  final Set<String> initialSelections;

  const AllergySelectorScreen({
    super.key,
    required this.onRestrictionsChanged,
    required this.initialSelections,
  });

  @override
  State<AllergySelectorScreen> createState() => _AllergySelectorScreenState();
}

class _AllergySelectorScreenState extends State<AllergySelectorScreen> {
  final Map<String, List<String>> allergyOptions = {
    'Allergies (Veggies)': ['Bell Pepper','Basil', 'Tomato', 'Olive Oil', 'Garlic', 'Onion', 'Cilantro', 'Quinoa', 'Cucumber'],
    'Allergies (Seeds)': ['Sesame', 'Soy Sauce'],
    'Allergies (Fruit)': ['Avocado'],
    'Lactose Intolerance': ['Milk', 'Feta'],
    'Gluten Free Exlusions & Other Grains': ['Wheat', 'Barley', 'Bread', 'Tortilla', 'Rice', 'Pasta'],
    'Vegan / Vegetarian Exclusions': ['Salmon', 'Egg', 'Beef', 'Chicken', 'Duck'],
  };

  late Map<String, bool> selectedIngredients;

  @override
  void initState() {
    super.initState();
    selectedIngredients = {
      for (var i in allergyOptions.values.expand((i) => i))
        i: widget.initialSelections.contains(i),
    };
  }

  void _updateSelections(String ingredient, bool isSelected) {
    setState(() {
      selectedIngredients[ingredient] = isSelected;
      widget.onRestrictionsChanged(
        selectedIngredients.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toSet(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: allergyOptions.entries.map((entry) {
          final category = entry.key;
          final items = entry.value;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ExpansionTile(
              title: Text(category),
              children: items.map((ingredient) {
                return CheckboxListTile(
                  title: Text(ingredient),
                  value: selectedIngredients[ingredient],
                  onChanged: (bool? value) {
                    _updateSelections(ingredient, value ?? false);
                  },
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  final String userName;
  final List<Recipe> bookmarkedRecipes;   // <-- add this
  final List<Recipe> favoriteRecipes;
  
  const ProfilePage({
    super.key, 
    this.userName = 'User', 
    required this.bookmarkedRecipes,      // <-- constructor param
    required this.favoriteRecipes,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut(); // Firebase sign out
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomePageWrapper()),
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
     final user = FirebaseAuth.instance.currentUser; //Current Firebase user
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Profile"),
        backgroundColor: Colors.green[700],
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showSettingsMenu(context),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const SizedBox(height: 30),
          // Profile Picture Circle
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF5aa454),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 3),
                ),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Upload profile picture feature coming soon!')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF5aa454), width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Color(0xFF5aa454),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // User Name
          // AUTH INFO (FirebaseAuth)
          Text(
            user?.email ?? 'No email',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 20),

          //  FIRESTORE PROFILE DETAILS
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              final data = snapshot.data!.data();
              if (data == null) {
                return const Text('No profile data found');
              }

              return Column(
                children: [
                  Text('First name: ${data['firstName'] ?? ''}'),
                  Text('Last name: ${data['lastName'] ?? ''}'),
                  Text('Phone: ${data['phone'] ?? ''}'),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          //  Stats Row (Posts, Followers, Following)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('recipes')
                    .where('createdBy',
                        isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildStatColumn('Posts', '0');
                  }
                  final count = snapshot.data!.docs.length;
                  return _buildStatColumn('Posts', '$count');
                },
              ),

              _buildStatColumn('Followers', '0'),
              _buildStatColumn('Following', '0'),
            ],
          ),

          const SizedBox(height: 20),

          //  TabBar for Posts, Saved and Favorites
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF5aa454),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF5aa454),
            tabs: const [
              Tab(icon: Icon(Icons.grid_on), text: 'Posts'),
              Tab(icon: Icon(Icons.bookmark), text: 'Saved'),
              Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
            ],
          ),

          //  TabBarView with recipe grids
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('recipes')
                      .where('createdBy',
                          isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final recipes = snapshot.data!.docs
                        .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>))
                        .toList();

                    return _buildRecipeGrid(recipes);                  
                  },
                ),
                // Saved tab
              _buildRecipeGrid(widget.bookmarkedRecipes.toList()), 
              // Favorites tab
              _buildRecipeGrid(widget.favoriteRecipes.toList()), 

              ],
            ),
          ),
        ],
      ),
    );
  }


  void _showSettingsMenu(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              ExpansionTile(
              leading: const Icon(Icons.info, color: Color(0xFF5aa454)),
              title: const Text('Profile Info'),
              children: [
                ListTile(
                  title: Text('Email: ${user?.email ?? ''}'),
                ),
                ListTile(
                  title: Text('UID: ${user?.uid ?? ''}'),
                ),
                ListTile(
                  title: Text('Created: ${user?.metadata.creationTime}'),
                ),
                ListTile(
                  title: Text('Last login: ${user?.metadata.lastSignInTime}'),
                ),
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const ListTile(title: Text('Loading...'));
                    }
                    final data = snapshot.data!.data();
                    if (data == null) {
                      return const ListTile(title: Text('No profile data found'));
                    }
                    return Column(
                      children: [
                        ListTile(title: Text('First name: ${data['firstName'] ?? ''}')),
                        ListTile(title: Text('Last name: ${data['lastName'] ?? ''}')),
                        ListTile(title: Text('Phone: ${data['phone'] ?? ''}')),
                      ],
                    );
                  },
                ),
              ],
            ),

              ListTile(
                leading: const Icon(Icons.settings, color: Color(0xFF5aa454)),
                title: const Text('Account Settings'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account settings coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock, color: Color(0xFF5aa454)),
                title: const Text('Privacy'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy settings coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Color(0xFF5aa454)),
                title: const Text('Help & Support'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help & support coming soon!')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSignOutDialog(context);
                },
              ),
            ],
          ),
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

  Widget _buildRecipeGrid(List<Recipe> recipes){
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
          onTap: () {
            _showRecipeDetail(recipe);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
            ),
            child: Image.network(
              recipe.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.restaurant, size: 40, color: Colors.grey),
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
                    color: const Color(0xFF5aa454),
                  ),
                );
              },
            ),
          ),
        );
      },
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
              // Recipe Image
              Container(
                width: double.infinity,
                height: 250,
                child: Image.network(
                  recipe.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.restaurant, size: 60, color: Colors.grey),
                      ),
                    );
                  },
                ),
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: (recipe.hashtags as List<String>).map((tag) {
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
}

class UserRecipesPage extends StatefulWidget {
  const UserRecipesPage({super.key});

  @override
  State<UserRecipesPage> createState() => _UserRecipesPageState();
}

class _UserRecipesPageState extends State<UserRecipesPage> {

  Future<void> _addRecipe(String name, String ingredients) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('recipes').add({
      'name': name,
      'ingredients': ingredients.split(',').map((i) => i.trim()).toList(),
      'rating': 0.0,
      'ratingCount': 0,
      'isShared': false,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }


  Future<void> _toggleShare(String docId, bool currentValue) async {
    await FirebaseFirestore.instance
        .collection('recipes')
        .doc(docId)
        .update({'isShared': !currentValue});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(!currentValue
            ? 'Recipe shared with community!'
            : 'Recipe made private'),
        backgroundColor: const Color(0xFF5aa454),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;
  return Scaffold(
    appBar: AppBar(
      title: const Text("Your Recipes"),
      backgroundColor: const Color(0xFF5aa454),
    ),
    body: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes')
          .where('createdBy', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final recipes = snapshot.data!.docs;

        if (recipes.isEmpty) {
          return const Center(
            child: Text(
              'No recipes yet. Add one!',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final doc = recipes[index];
            final recipe = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        recipe['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (recipe['isShared'])
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.public, size: 14, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Shared',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("Ingredients: ${recipe['ingredients'] ?? ''}"),
                    if (recipe['ratingCount'] > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe['rating'].toStringAsFixed(1)} '
                            '(${recipe['ratingCount']} ratings)',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    recipe['isShared'] ? Icons.public : Icons.lock,
                    color:
                        recipe['isShared'] ? Colors.green : Colors.grey,
                  ),
                  onPressed: () => _toggleShare(
                    doc.id,
                    recipe['isShared'] as bool,
                  ),
                  tooltip: recipe['isShared']
                      ? 'Make private'
                      : 'Share with community',
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Recipe details coming soon!')),
                  );
                },
              ),
            );
          },
        );
      },
    ), // 👈 close StreamBuilder properly here
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddRecipePage(onAddRecipe: _addRecipe),
          ),
        );
      },
      backgroundColor: const Color(0xFF5aa454),
      child: const Icon(Icons.add),
    ),
  );
}
}

class AddRecipePage extends StatefulWidget {
  final Future<void> Function(String name, String ingredients) onAddRecipe;

  const AddRecipePage({super.key, required this.onAddRecipe});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}


class _AddRecipePageState extends State<AddRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final _recipeNameController = TextEditingController();
  final _ingredientsController = TextEditingController();

  @override
  void dispose() {
    _recipeNameController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  Future<void> _submitRecipe() async {
  if (_formKey.currentState!.validate()) {
    //  Call the callback you passed in from UserRecipesPage
    await widget.onAddRecipe(
      _recipeNameController.text.trim(),
      _ingredientsController.text.trim(),
    );

    // Close the AddRecipePage
    Navigator.pop(context);

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recipe added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Recipe"),
        backgroundColor: const Color(0xFF5aa454),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create Your Recipe',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _recipeNameController,
                decoration: InputDecoration(
                  labelText: 'Recipe Name',
                  hintText: 'Enter recipe name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.restaurant),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a recipe name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _ingredientsController,
                decoration: InputDecoration(
                  labelText: 'Ingredients',
                  hintText: 'Enter ingredients separated by commas',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.list),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter ingredients';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5aa454),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add Recipe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SavedRecipesPage extends StatelessWidget {
  final Set<Meal> savedRecipes;

  const SavedRecipesPage({super.key, required this.savedRecipes});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Recipes"),
        backgroundColor: const Color(0xFF5aa454),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('saved')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final meals = snapshot.data!.docs
            .map((doc) => Meal.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

          if (savedRecipes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No saved recipes yet',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Heart recipes from the meal prep page to save them here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedRecipes.length,
              itemBuilder: (context, index) {
                final meal = savedRecipes.elementAt(index);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      meal.icon,
                      color: meal.color,
                      size: 40,
                    ),
                    title: Text(
                      meal.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: meal.color,
                      ),
                    ),
                    subtitle: Text(
                      'Tap to view ingredients',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            meal.name,
                            style: TextStyle(color: meal.color),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(meal.icon, color: meal.color),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Ingredients:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...meal.ingredients.map(
                                (ingredient) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle, size: 8),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(ingredient)),
                                    ],
                                  ),
                                ),
                              ),
                              if (meal.restrictions.isNotEmpty) ...[
                                const SizedBox(height: 15),
                                const Text(
                                  'Restrictions:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  meal.restrictions.join(', '),
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

