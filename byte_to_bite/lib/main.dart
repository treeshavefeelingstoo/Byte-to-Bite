import 'package:flutter/material.dart';
import 'package:byte_to_bite/Pages/Welcome/welcome_page.dart';
import 'package:byte_to_bite/constants.dart';
import 'package:byte_to_bite/pages/Jcode/jaislen.dart';
import 'package:byte_to_bite/Pages/HomePage/home_page.dart';


import 'dart:io';
import 'dart:convert';


void main() => runApp (MyApp());

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
  
  const DietaryApp({super.key, required this.userName});

  @override
  State<DietaryApp> createState() => _DietaryAppState();
}

class _DietaryAppState extends State<DietaryApp> {
  int _selectedIndex = 0;
  Set<String> excludedIngredients = {};

  final Map<DateTime, List<Meal>> _mealPlan = {};
  final Map<DateTime, Set<String>> _groceriesByWeek = {};
  final Map<String, bool> _checkedGroceries = {};
  final Set<Meal> _savedRecipes = {}; 

  @override
  void initState() {
    super.initState();
    _loadExclusions();
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

    void _toggleSaveRecipe(Meal meal) {
      setState(() {
        final existingMeal = _savedRecipes.firstWhere(
          (m) => m.name == meal.name,
          orElse: () => meal,
        );
        if (_savedRecipes.contains(existingMeal)) {
          _savedRecipes.remove(existingMeal);
        } else {
          _savedRecipes.add(meal);
        }
      });
    }


  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(
        mealPlan: _mealPlan,
        onWeekGroceriesChanged: _handleWeekGroceriesChanged,
        getWeekGroceries: _getWeekGroceries,
        excludedIngredients: excludedIngredients,
        userName: widget.userName,
      ),
      AllergySelectorScreen(
        onRestrictionsChanged: _updateExclusions,
        initialSelections: excludedIngredients,
      ),
      MealPlannerPage(
        mealPlan: _mealPlan,
        onWeekGroceriesChanged: _handleWeekGroceriesChanged,
        getWeekGroceries: _getWeekGroceries,
        excludedIngredients: excludedIngredients,
        savedRecipes: _savedRecipes,
        onToggleSaveRecipe: _toggleSaveRecipe,
      ),

      GroceryPage(
        groceriesByWeek: _groceriesByWeek,
        checkedGroceries: _checkedGroceries,
        onToggleItem: _toggleGroceryItem,
        onDeleteWeek: _deleteWeek,
        onBackToMealPrep: () => setState(() => _selectedIndex = 2),
      ),
      ProfilePage(userName: widget.userName, savedRecipes: _savedRecipes),
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
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
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
        builder: (_) => DietaryApp(userName: widget.userName),
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

class ProfilePage extends StatelessWidget{
  final String userName;
  final Set<Meal> savedRecipes;
  
  const ProfilePage({super.key, this.userName = 'User', required this.savedRecipes});

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
              onPressed: () {
                Navigator.of(context).pop(); 
                // Navigate to the welcome page
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Profile"),
        backgroundColor: Colors.green[700],
        automaticallyImplyLeading: false,
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
          Text(
            userName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 25),
          // Followers and Following Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Followers list coming soon!')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF5aa454), width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text(
                  'Followers: 0',
                  style: TextStyle(
                    color: Color(0xFF5aa454),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Following list coming soon!')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF5aa454), width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text(
                  'Following: 0',
                  style: TextStyle(
                    color: Color(0xFF5aa454),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Saved Recipes and Your Recipes buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedRecipesPage(savedRecipes: savedRecipes),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5aa454),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.favorite),
                label: const Text(
                  'Saved Recipes',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 15),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserRecipesPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5aa454),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.restaurant),
                label: const Text(
                  'Your Recipes',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showSignOutDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Sign Out / Log In to Another Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      )
    );
  }
}

class UserRecipesPage extends StatefulWidget {
  const UserRecipesPage({super.key});

  @override
  State<UserRecipesPage> createState() => _UserRecipesPageState();
}

class _UserRecipesPageState extends State<UserRecipesPage> {
  final List<Map<String, String>> _userRecipes = [
    {
      'name': 'Hummus',
      'ingredients': 'Chickpeas, Tahini, Olive Oil',
    },
  ];

  void _addRecipe(String name, String ingredients) {
    setState(() {
      _userRecipes.add({
        'name': name,
        'ingredients': ingredients,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Recipes"),
        backgroundColor: const Color(0xFF5aa454),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _userRecipes.length,
        itemBuilder: (context, index) {
          final recipe = _userRecipes[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(
                recipe['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Text("Ingredients: ${recipe['ingredients'] ?? ''}"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recipe details soon!')),
                );
              },
            ),
          );
        },
      ),
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
  final Function(String name, String ingredients) onAddRecipe;

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

  void _submitRecipe() {
    if (_formKey.currentState!.validate()) {
      widget.onAddRecipe(
        _recipeNameController.text.trim(),
        _ingredientsController.text.trim(),
      );
      Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Recipes"),
        backgroundColor: const Color(0xFF5aa454),
      ),
      body: savedRecipes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey,
                  ),
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
            )
          : ListView.builder(
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
            ),
    );
  }
}
