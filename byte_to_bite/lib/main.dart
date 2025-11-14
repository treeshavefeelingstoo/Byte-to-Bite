import 'package:flutter/material.dart';
import 'package:byte_to_bite/Pages/Welcome/welcome_page.dart';
import 'package:byte_to_bite/constants.dart';
import 'package:byte_to_bite/pages/Jcode/jaislen.dart';


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
          MaterialPageRoute(builder: (_) => const DietaryApp()),
        );
      },
    );
  }
}


class DietaryApp extends StatefulWidget {
  const DietaryApp({super.key});

  @override
  State<DietaryApp> createState() => _DietaryAppState();
}

class _DietaryAppState extends State<DietaryApp> {
  int _selectedIndex = 0;
  Set<String> excludedIngredients = {};

  final Map<DateTime, List<Meal>> _mealPlan = {};
  final Map<DateTime, Set<String>> _groceriesByWeek = {};
  final Map<String, bool> _checkedGroceries = {};

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


  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeScreen(),
      AllergySelectorScreen(
        onRestrictionsChanged: _updateExclusions,
        initialSelections: excludedIngredients,
      ),
      MealPlannerPage(
        mealPlan: _mealPlan,
        onWeekGroceriesChanged: _handleWeekGroceriesChanged,
        getWeekGroceries: _getWeekGroceries,
        excludedIngredients: excludedIngredients, 
      ),

      GroceryPage(
        groceriesByWeek: _groceriesByWeek,
        checkedGroceries: _checkedGroceries,
        onToggleItem: _toggleGroceryItem,
        onDeleteWeek: _deleteWeek,
      ),
    ];

      return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.green[700], // ✅ sets nav bar background
        primaryColor: Colors.white,     // ✅ active icon color
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
