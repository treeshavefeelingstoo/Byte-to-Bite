import 'package:flutter/material.dart';



class Meal {
  final String name;
  final List<String> ingredients;
  final List<String> restrictions;
  final Color color;
  final IconData icon;

  Meal(
    this.name,
    this.ingredients, {
    this.restrictions = const [],
    this.color = Colors.blue,
    this.icon = Icons.restaurant,
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
    final weeks = widget.groceriesByWeek.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    final now = DateTime.now();
    final currentWeekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday % 7));

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
          ? const Center(
              child: Text("No groceries yet. Add meals to populate weekly lists."))
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
                              "Are you sure you want to delete the grocery list and all meals for the week of ${weekStart.month}/${weekStart.day}/${weekStart.year}?"
                            ),
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text("Delete", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip: "Delete this week",
                    ),
                    children: [
                      for (final item in items)
                        CheckboxListTile(
                          value: widget.checkedGroceries[_getItemKey(weekStart, item)] ?? false,
                          onChanged: (bool? value) {
                            widget.onToggleItem(weekStart, item);
                            setState(() {});
                          },
                          title: Text(
                            item,
                            style: TextStyle(
                              decoration: (widget.checkedGroceries[_getItemKey(weekStart, item)] ?? false)
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: (widget.checkedGroceries[_getItemKey(weekStart, item)] ?? false)
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


  const MealPlannerPage({
    super.key,
    required this.mealPlan,
    required this.onWeekGroceriesChanged,
    required this.getWeekGroceries,
    required this.excludedIngredients,
  });

  @override
  State<MealPlannerPage> createState() => _MealPlannerPageState();
}

class _MealPlannerPageState extends State<MealPlannerPage> {
  DateTime _currentMonth = DateTime.now();
  bool _isMonthView = true;
  DateTime _selectedDate = DateTime.now();

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _weekStart(DateTime d) {
    final normalized = _normalize(d);
    final delta = normalized.weekday % 7;
    return normalized.subtract(Duration(days: delta));
  }

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

  Future<void> _addMeal(DateTime date) async {
    final meal = await Navigator.push(
      context,
      MaterialPageRoute(
    builder: (context) => RecipePage(excludedIngredients: widget.excludedIngredients),
      ),
    );
    if (meal != null && meal is Meal) {
      final key = _normalize(date);
      setState(() {
        widget.mealPlan.putIfAbsent(key, () => []).add(meal);
      });
      final week = _weekStart(key);
      final currentItems = widget.getWeekGroceries(week);
      final updated = <String>{...currentItems, ...meal.ingredients};
      widget.onWeekGroceriesChanged(week, updated);
    }
  }

  void _showMeals(DateTime date) {
    final key = _normalize(date);
    final meals = widget.mealPlan[key] ?? [];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Meals for ${date.month}/${date.day}/${date.year}"),
          content: meals.isEmpty
              ? const Text("No meals added yet.")
              : SizedBox(
                  width: 360,
                  height: 320,
                  child: ListView.builder(
                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      final meal = meals[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        color: meal.color.withOpacity(0.1),
                        child: ListTile(
                          leading: Icon(meal.icon, color: meal.color),
                          title: Text(meal.name, style: TextStyle(color: meal.color, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Ingredients: ${meal.ingredients.join(", ")}"),
                              if (meal.restrictions.isNotEmpty)
                                Text("Restrictions: ${meal.restrictions.join(", ")}",
                                    style: const TextStyle(color: Colors.red)),
                            ],
                          ),
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
                _addMeal(date);
              },
              child: const Text("Add Meal"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickYear() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Year'),
          children: List.generate(10, (i) {
            final year = DateTime.now().year - 5 + i;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, year),
              child: Text(year.toString()),
            );
          }),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _currentMonth = DateTime(picked, _currentMonth.month, 1);
      });
    }
  }

  Widget _buildMonthGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startOffset = firstDay.weekday % 7;
    final totalDays = lastDay.day;
    final totalCells = ((startOffset + totalDays) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < startOffset || index >= startOffset + totalDays) {
          return const SizedBox();
        }
        final day = index - startOffset + 1;
        final date = DateTime(_currentMonth.year, _currentMonth.month, day);
        final meals = widget.mealPlan[_normalize(date)] ?? [];

        return GestureDetector(
          onTap: () => _showMeals(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: meals.isEmpty ? Colors.grey[200] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontWeight: meals.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (meals.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    alignment: WrapAlignment.center,
                    children: meals.take(3).map((meal) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: meal.color,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                  if (meals.length > 3)
                    Text(
                      '+${meals.length - 3}',
                      style: const TextStyle(fontSize: 8),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekRow() {
    final week = _weekStart(_selectedDate);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontWeight: meals.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  if (meals.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...meals.take(2).map((meal) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Icon(meal.icon, size: 16, color: meal.color),
                        )),
                    if (meals.length > 2)
                      Text(
                        '+${meals.length - 2}',
                        style: const TextStyle(fontSize: 10),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWeekGroceries() {
    final week = _weekStart(_selectedDate);
    
    final Map<String, List<String>> groceriesByMeal = {};
    
    for (int i = 0; i < 7; i++) {
      final date = week.add(Duration(days: i));
      final meals = widget.mealPlan[_normalize(date)] ?? [];
      for (final meal in meals) {
        groceriesByMeal.putIfAbsent(meal.name, () => []);
        for (final ingredient in meal.ingredients) {
          if (!groceriesByMeal[meal.name]!.contains(ingredient)) {
            groceriesByMeal[meal.name]!.add(ingredient);
          }
        }
      }
    }

    if (groceriesByMeal.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Grocery List for This Week",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text("No groceries yet. Add meals to generate list."),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Grocery List by Meal",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...groceriesByMeal.entries.map((entry) {
            Meal? mealObj;
            for (final meals in widget.mealPlan.values) {
              for (final m in meals) {
                if (m.name == entry.key) {
                  mealObj = m;
                  break;
                }
              }
              if (mealObj != null) break;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: mealObj?.color.withOpacity(0.1) ?? Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: mealObj?.color ?? Colors.grey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(mealObj?.icon ?? Icons.restaurant, 
                           size: 20, 
                           color: mealObj?.color ?? Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: mealObj?.color ?? Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...entry.value.map((ingredient) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const SizedBox(width: 28),
                            const Icon(Icons.check_box_outline_blank, size: 16),
                            const SizedBox(width: 8),
                            Text(ingredient, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      )),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const monthNames = [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ];
    final monthName = monthNames[_currentMonth.month - 1];
    final weekLabelStart = _weekStart(_selectedDate);

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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back), onPressed: _previous),
                    Column(
                      children: [
                        Text(
                          _isMonthView
                              ? "$monthName ${_currentMonth.year}"
                              : "Week of ${weekLabelStart.month}/${weekLabelStart.day}/${weekLabelStart.year}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (_isMonthView)
                          InkWell(
                            onTap: _pickYear,
                            child: const Text(
                              "Change year",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _next),
                  ],
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Sun", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text("Mon", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text("Tue", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text("Wed", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text("Thu", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text("Fri", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text("Sat", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                _isMonthView ? _buildMonthGrid() : _buildWeekRow(),
                const SizedBox(height: 12),
                if (!_isMonthView) _buildWeekGroceries(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecipePage extends StatelessWidget {
  const RecipePage({super.key, required this.excludedIngredients});

  final Set<String> excludedIngredients;


  @override
  Widget build(BuildContext context) {
    final sampleRecipes = <Meal>[
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

    final filteredRecipes = sampleRecipes.where((meal) {
      return !meal.ingredients.any(excludedIngredients.contains);
    }).toList();


    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick a Recipe"),
        backgroundColor: const Color(0xFF5aa454),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        itemCount: filteredRecipes.length,
        itemBuilder: (context, index) {
          final meal = filteredRecipes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              leading: Icon(meal.icon, color: meal.color, size: 32),
              title: Text(
                meal.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ingredients: ${meal.ingredients.join(", ")}"),
                  if (meal.restrictions.isNotEmpty)
                    Text(
                      "Restrictions: ${meal.restrictions.join(", ")}",
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
              isThreeLine: true,
              onTap: () {
                Navigator.pop(context, meal);
              },
            ),
          );
        },
      ),
    );
  }
}
