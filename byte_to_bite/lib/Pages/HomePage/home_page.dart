import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:byte_to_bite/pages/Jcode/jaislen.dart';

class HomePage extends StatefulWidget {
  final Map<DateTime, List<Meal>>? mealPlan;   // <-- nullable
  final void Function(DateTime weekStart, Set<String> items)? onWeekGroceriesChanged;
  final Set<String> Function(DateTime weekStart)? getWeekGroceries;
  final Set<String>? excludedIngredients;
  final String userName;

  const HomePage({
    super.key,
    this.mealPlan,
    this.onWeekGroceriesChanged,
    this.getWeekGroceries,
    this.excludedIngredients,
    this.userName = 'User',
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Meal> _generatedMeals = [];
  final Set<int> _selectedMealIndices = {};

  void _generateRandomMeals() {
    // Sample meals pool
    final List<Meal> allMeals = [
      Meal('Grilled Chicken Salad', ['Chicken', 'Lettuce', 'Tomato', 'Olive Oil'],
          color: Colors.green, icon: Icons.restaurant),
      Meal('Pasta Primavera', ['Pasta', 'Bell Pepper', 'Zucchini', 'Garlic'],
          color: Colors.orange, icon: Icons.dinner_dining),
      Meal('Salmon with Vegetables', ['Salmon', 'Broccoli', 'Carrots', 'Lemon'],
          color: Colors.blue, icon: Icons.set_meal),
      Meal('Veggie Stir Fry', ['Tofu', 'Bok Choy', 'Mushrooms', 'Soy Sauce'],
          color: Colors.purple, icon: Icons.ramen_dining),
      Meal('Turkey Sandwich', ['Turkey', 'Bread', 'Lettuce', 'Mayo'],
          color: Colors.brown, icon: Icons.lunch_dining),
      Meal('Beef Tacos', ['Beef', 'Tortilla', 'Cheese', 'Salsa'],
          color: Colors.red, icon: Icons.fastfood),
      Meal('Greek Salad', ['Feta', 'Olives', 'Cucumber', 'Tomato'],
          color: Colors.teal, icon: Icons.restaurant_menu),
      Meal('Chicken Curry', ['Chicken', 'Curry Powder', 'Coconut Milk', 'Rice'],
          color: Colors.amber, icon: Icons.ramen_dining),
    ];

    // Filter out meals with excluded ingredients
    final exclusions = widget.excludedIngredients?.map((e) => e.toLowerCase()).toSet() ?? {};

    final availableMeals = allMeals.where((meal) {
      return !meal.ingredients.any((ingredient) =>
        exclusions.contains(ingredient.toLowerCase()));
    }).toList();

    if (availableMeals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No meals available with your restrictions')),
      );
      return;
    }

    // Shuffle and take random meals
    availableMeals.shuffle();
    setState(() {
      _generatedMeals = availableMeals.take(5).toList();
      _selectedMealIndices.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generated 5 random meals!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _addSelectedMealsToCalendar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in')),
      );
      return;
    }

    if (_selectedMealIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one meal')),
      );
      return;
    }

    final repo = MealPlanRepo();
    final now = DateTime.now();
    final currentWeekStart = weekStartOf(now);

    int dayOffset = 1; // start from Monday
    for (int index in _selectedMealIndices.toList()..sort()) {
      if (index < _generatedMeals.length) {
        final meal = _generatedMeals[index];
        final date = currentWeekStart.add(Duration(days: dayOffset));

        // 🔥 Persist to Firestore
        await repo.addMeal(date: date, meal: meal, mealType: meal.mealType);
        await repo.addGroceries(date: date, ingredients: meal.ingredients);

        dayOffset++;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${_selectedMealIndices.length} meal(s) to calendar & groceries'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _selectedMealIndices.clear();
      _generatedMeals.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // bar at the top with user name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: const BoxDecoration(
              color: Color(0xFF5aa454),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${widget.userName}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ready to plan your meals?',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: Color(0xFF5aa454),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Generate Your Weekly Meals',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Create a personalized meal plan for the week based on your dietary restrictions',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _generateRandomMeals,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5aa454),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Generate Random Meals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Display generated meals
                  if (_generatedMeals.isNotEmpty) ...[
                    const Text(
                      'Select meals to add:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ...List.generate(_generatedMeals.length, (index) {
                      final meal = _generatedMeals[index];
                      final isSelected = _selectedMealIndices.contains(index);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: isSelected ? meal.color.withOpacity(0.3) : Colors.white,
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedMealIndices.add(index);
                              } else {
                                _selectedMealIndices.remove(index);
                              }
                            });
                          },
                          title: Row(
                            children: [
                              Icon(meal.icon, color: meal.color),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  meal.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: meal.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Ingredients: ${meal.ingredients.join(", ")}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          activeColor: meal.color,
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _selectedMealIndices.isNotEmpty ? _addSelectedMealsToCalendar : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5aa454),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Select Meals to Add to Calendar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
