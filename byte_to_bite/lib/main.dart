import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

void main() => runApp(const DietaryApp());

class DietaryApp extends StatefulWidget {
  const DietaryApp({super.key});

  @override
  State<DietaryApp> createState() => _DietaryAppState();
}

class _DietaryAppState extends State<DietaryApp> {
  int _selectedIndex = 0;
  Set<String> excludedIngredients = {};

  @override
  void initState() {
    super.initState();
    _loadExclusions();
  }

  Future<File> getLocalFile() async {
    final directory = Directory.systemTemp; // Temporary storage
    return File('${directory.path}/excluded_ingredients.json');
  }

  Future<void> _saveExclusions(Set<String> exclusions) async {
    final file = await getLocalFile();
    final jsonString = jsonEncode(exclusions.toList());
    await file.writeAsString(jsonString);
  }

  Future<void> _loadExclusions() async {
    final file = await getLocalFile();
    if (await file.exists()) {
      final jsonString = await file.readAsString();
      final List<dynamic> decoded = jsonDecode(jsonString);
      setState(() {
        excludedIngredients = decoded.cast<String>().toSet();
      });
    }
  }

  void _updateExclusions(Set<String> exclusions) {
    setState(() {
      excludedIngredients = exclusions;
    });
    _saveExclusions(exclusions);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeScreen(),
      RecipeScreen(excludedIngredients: excludedIngredients),
      AllergySelectorScreen(
        onRestrictionsChanged: _updateExclusions,
        initialSelections: excludedIngredients,
      ),
    ];

    return MaterialApp(
      title: 'Dietary Restrictions',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFE0F2E0),
      ),
      home: Scaffold(
        body: pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.green[700],
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Home Screen', style: TextStyle(fontSize: 24)),
    );
  }
}

class RecipeScreen extends StatelessWidget {
  final Set<String> excludedIngredients;

  const RecipeScreen({super.key, required this.excludedIngredients});

  final List<Map<String, dynamic>> allRecipes = const [
    {
      'name': 'Orange Smoothie',
      'ingredients': ['Oranges', 'Milk', 'Honey'],
    },
    {
      'name': 'Grilled Cheese',
      'ingredients': ['Bread', 'Cheese', 'Butter'],
    },
    {
      'name': 'Pear Salad',
      'ingredients': ['Pears', 'Lettuce', 'Walnuts'],
    },
    {
      'name': 'Veggie Stir Fry',
      'ingredients': ['Broccoli', 'Carrots', 'Soy Sauce'],
    },
  ];

  List<Map<String, dynamic>> get filteredRecipes {
    return allRecipes.where((recipe) {
      final ingredients = recipe['ingredients'] as List<String>;
      return !ingredients.any(excludedIngredients.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: filteredRecipes.map((recipe) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(recipe['name']),
            subtitle: Text('Ingredients: ${recipe['ingredients'].join(', ')}'),
          ),
        );
      }).toList(),
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
    'Allergies': ['Oranges', 'Pears'],
    'Lactose Intolerance': ['Milk', 'Cheese'],
    'Gluten Free': ['Wheat', 'Barley'],
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
      appBar: AppBar(
        title: const Text('Select Dietary Restrictions'),
        backgroundColor: Colors.green[700],
      ),
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