import 'package:flutter/material.dart';

class Meal {
  final String name;
  final List<String> ingredients;
  final List<String> restrictions;
  final Color color;
  final IconData icon;
  final String mealType;

  Meal(
    this.name,
    this.ingredients, {
    this.restrictions = const [],
    this.color = Colors.blue,
    this.icon = Icons.restaurant,
    this.mealType = "lunch",
  });
}

class GroceryPage extends StatefulWidget {
  final Map<DateTime, Set<String>> groceriesByWeek;
  final Map<String, bool> checkedGroceries;
  final Function(DateTime weekStart, String item) onToggleItem;
  final Function(DateTime weekStart) onDeleteWeek;
  final VoidCallback onBackToMealPrep;

  const GroceryPage({
    super.key,
    required this.groceriesByWeek,
    required this.checkedGroceries,
    required this.onToggleItem,
    required this.onDeleteWeek,
    required this.onBackToMealPrep,
  });

  @override
  State<GroceryPage> createState() => _GroceryPageState();
}

class _GroceryPageState extends State<GroceryPage> {
  String _getItemKey(DateTime weekStart, String item) {
    return '${weekStart.millisecondsSinceEpoch}_$item';
  }

  @override
  Widget build(BuildContext context) {
    final weeks = widget.groceriesByWeek.keys.toList()..sort((a, b) => b.compareTo(a));
    final now = DateTime.now();
    final currentWeekStart =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday % 7));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Grocery List"),
        backgroundColor: const Color(0xFF5aa454),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackToMealPrep,
        ),
      ),
      body: weeks.isEmpty
          ? const Center(child: Text("No groceries yet. Add meals to populate weekly lists."))
          : ListView.builder(
              itemCount: weeks.length,
              itemBuilder: (context, index) {
                final weekStart = weeks[index];
                final items = widget.groceriesByWeek[weekStart]!.toList()..sort();
                final isCurrentWeek = weekStart.isAtSameMomentAs(currentWeekStart);

                final checkedCount = items.where((item) {
                  final key = _getItemKey(weekStart, item);
                  return widget.checkedGroceries[key] ?? false;
                }).length;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ExpansionTile(
                    initiallyExpanded: isCurrentWeek,
                    title: Text("Week of ${weekStart.month}/${weekStart.day}/${weekStart.year}"),
                    subtitle: Text(
                      "$checkedCount/${items.length} completed",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Delete Week"),
                            content: Text(
                                "Delete all groceries and meals for the week of ${weekStart.month}/${weekStart.day}/${weekStart.year}?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  widget.onDeleteWeek(weekStart);
                                  Navigator.pop(context);
                                  setState(() {});
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text("Delete", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    children: [
                      for (final item in items)
                        CheckboxListTile(
                          value: widget.checkedGroceries[_getItemKey(weekStart, item)] ?? false,
                          onChanged: (bool? _) {
                            widget.onToggleItem(weekStart, item);
                            setState(() {});
                          },
                          title: Text(
                            item,
                            style: TextStyle(
                              decoration: (widget.checkedGroceries[_getItemKey(weekStart, item)] ??
                                      false)
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: (widget.checkedGroceries[_getItemKey(weekStart, item)] ??
                                      false)
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          activeColor: Colors.green,
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class MealPlannerPage extends StatefulWidget {
  final Map<DateTime, List<Meal>> mealPlan;
  final void Function(DateTime weekStart, Set<String> items) onWeekGroceriesChanged;
  final Set<String> Function(DateTime weekStart) getWeekGroceries;

  final Set<String> excludedIngredients;
  final Set<Meal>? savedRecipes;
  final void Function(Meal meal)? onToggleSaveRecipe;

  const MealPlannerPage({
    super.key,
    required this.mealPlan,
    required this.onWeekGroceriesChanged,
    required this.getWeekGroceries,
    required this.excludedIngredients,
    this.savedRecipes,
    this.onToggleSaveRecipe,
  });

  @override
  State<MealPlannerPage> createState() => _MealPlannerPageState();
}

class _MealPlannerPageState extends State<MealPlannerPage> {
  DateTime _currentMonth = DateTime.now();
  bool _isMonthView = true;
  DateTime _selectedDate = DateTime.now();

  DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);
  DateTime _weekStart(DateTime d) =>
      _normalize(d).subtract(Duration(days: _normalize(d).weekday % 7));

  void _next() {
    setState(() {
      if (_isMonthView) {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      } else {
        _selectedDate = _selectedDate.add(const Duration(days: 7));
      }
    });
  }

  void _previous() {
    setState(() {
      if (_isMonthView) {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      } else {
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      }
    });
  }

  Future<void> _pickMealType(DateTime date) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text("Select Meal Type"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "breakfast"),
            child: const Text("Breakfast"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "lunch"),
            child: const Text("Lunch"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "dinner"),
            child: const Text("Dinner"),
          ),
        ],
      ),
    );

    if (selected != null) _addMeal(date, selected);
  }

  Future<void> _addMeal(DateTime date, String mealType) async {
    final meal = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipePage(excludedIngredients: widget.excludedIngredients),
      ),
    );

    if (meal != null && meal is Meal) {
      final key = _normalize(date);

      final updated = Meal(
        meal.name,
        meal.ingredients,
        restrictions: meal.restrictions,
        color: meal.color,
        icon: meal.icon,
        mealType: mealType,
      );

      setState(() {
        widget.mealPlan.putIfAbsent(key, () => []);
        widget.mealPlan[key]!.add(updated);
      });

      final week = _weekStart(key);
      final existing = widget.getWeekGroceries(week);
      final updatedGroceries = <String>{...existing, ...meal.ingredients};
      widget.onWeekGroceriesChanged(week, updatedGroceries);
    }
  }

  void _showMeals(DateTime date) {
    final key = _normalize(date);
    final meals = widget.mealPlan[key] ?? [];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Meals for ${date.month}/${date.day}/${date.year}"),
        content: SizedBox(
          width: 360,
          height: 320,
          child: meals.isEmpty
              ? const Center(child: Text("No meals yet"))
              : ListView.builder(
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(meal.icon, color: meal.color),
                        title: Text("${meal.mealType.toUpperCase()} • ${meal.name}"),
                        subtitle: Text("Ingredients: ${meal.ingredients.join(", ")}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              widget.mealPlan[key]?.removeAt(index);
                              if (widget.mealPlan[key]?.isEmpty ?? false) {
                                widget.mealPlan.remove(key);
                              }
                            });
                            Navigator.pop(context);
                            _showMeals(date);
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pickMealType(date);
            },
            child: const Text("Add Meal"),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    final offset = firstDay.weekday % 7;
    final totalDays = lastDay.day;
    final totalCells = ((offset + totalDays) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < offset || index >= offset + totalDays) return const SizedBox();

        final day = index - offset + 1;
        final date = DateTime(_currentMonth.year, _currentMonth.month, day);
        final meals = widget.mealPlan[_normalize(date)] ?? [];

        return GestureDetector(
          onTap: () => _showMeals(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: meals.isEmpty ? Colors.grey[200] : Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Column(
                children: [
                  Text(day.toString()),
                  if (meals.isNotEmpty)
                    Text("${meals.length} meals", style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekRow() {
    final week = _weekStart(_selectedDate);

    return Row(
      children: List.generate(7, (i) {
        final date = week.add(Duration(days: i));
        final meals = widget.mealPlan[_normalize(date)] ?? [];

        return Expanded(
          child: GestureDetector(
            onTap: () => _showMeals(date),
            child: Container(
              margin: const EdgeInsets.all(2),
              height: 80,
              decoration: BoxDecoration(
                color: meals.isEmpty ? Colors.grey[200] : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey),
              ),
              child: Column(
                children: [
                  Text("${date.day}"),
                  if (meals.isNotEmpty)
                    Text("${meals.length} meals", style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWeekMeals() {
    final week = _weekStart(_selectedDate);

    final Map<String, List<Meal>> grouped = {
      "breakfast": [],
      "lunch": [],
      "dinner": [],
    };

    for (int i = 0; i < 7; i++) {
      final date = week.add(Duration(days: i));
      final meals = widget.mealPlan[_normalize(date)] ?? [];
      for (final m in meals) {
        grouped[m.mealType]?.add(m);
      }
    }

    final total = grouped.values.fold<int>(0, (sum, list) => sum + list.length);
    if (total == 0) return const Text("No meals this week.");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (grouped["breakfast"]!.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text("Breakfast", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...grouped["breakfast"]!.map(
            (m) => Text("• ${m.name}  (${m.ingredients.join(", ")})"),
          ),
        ],
        if (grouped["lunch"]!.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text("Lunch", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...grouped["lunch"]!.map(
            (m) => Text("• ${m.name}  (${m.ingredients.join(", ")})"),
          ),
        ],
        if (grouped["dinner"]!.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text("Dinner", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...grouped["dinner"]!.map(
            (m) => Text("• ${m.name}  (${m.ingredients.join(", ")})"),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meal Planner"),
        backgroundColor: const Color(0xFF5aa454),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back), onPressed: _previous),
                  Text(
                    _isMonthView
                        ? "${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}"
                        : "Week of ${_weekStart(_selectedDate).month}/${_weekStart(_selectedDate).day}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _next),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text("Month"),
                    selected: _isMonthView,
                    onSelected: (_) => setState(() => _isMonthView = true),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("Week"),
                    selected: !_isMonthView,
                    onSelected: (_) => setState(() => _isMonthView = false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _isMonthView ? _buildMonthGrid() : _buildWeekRow(),
              const SizedBox(height: 16),
              if (!_isMonthView) _buildWeekMeals(),
            ],
          ),
        ),
      ),
    );
  }
}

class RecipePage extends StatelessWidget {
  final Set<String> excludedIngredients;

  const RecipePage({super.key, required this.excludedIngredients});

  @override
  Widget build(BuildContext context) {
    final sampleRecipes = [
      Meal(
        "Chicken Stir Fry",
        ["Chicken", "Bell Pepper", "Soy Sauce", "Garlic"],
        restrictions: ["Peanut Allergy Safe"],
        color: Colors.orange,
        icon: Icons.ramen_dining,
      ),
      Meal(
        "Veggie Pasta",
        ["Pasta", "Tomato", "Basil", "Olive Oil"],
        restrictions: ["Vegetarian"],
        color: Colors.green,
        icon: Icons.restaurant,
      ),
      Meal(
        "Salmon Bowl",
        ["Salmon", "Rice", "Avocado", "Sesame"],
        restrictions: ["Contains Fish"],
        color: Colors.pink,
        icon: Icons.set_meal,
      ),
      Meal(
        "Beef Tacos",
        ["Beef", "Tortilla", "Onion", "Cilantro"],
        restrictions: ["Contains Gluten"],
        color: Colors.red,
        icon: Icons.lunch_dining,
      ),
      Meal(
        "Quinoa Salad",
        ["Quinoa", "Cucumber", "Tomato", "Feta"],
        restrictions: ["Vegetarian"],
        color: Colors.teal,
        icon: Icons.eco,
      ),
    ];

    final available = sampleRecipes.where(
      (m) => !m.ingredients.any(excludedIngredients.contains),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick a Recipe"),
        backgroundColor: const Color(0xFF5aa454),
      ),
      body: ListView(
        children: available.map((meal) {
          return Card(
            child: ListTile(
              leading: Icon(meal.icon, color: meal.color),
              title: Text(meal.name),
              subtitle: Text("Ingredients: ${meal.ingredients.join(", ")}"),
              onTap: () => Navigator.pop(context, meal),
            ),
          );
        }).toList(),
      ),
    );
  }
}
