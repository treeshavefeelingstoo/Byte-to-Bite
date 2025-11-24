import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byte_to_bite/Pages/RecipePage/recipe_page.dart';

class Meal {
  final String name;
  final List<String> ingredients;
  final List<String> restrictions;
  final Color color;
  final IconData icon;
  final String mealType;

  const Meal(
    this.name,
    this.ingredients, {
    this.restrictions = const [],
    this.color = Colors.blue,
    this.icon = Icons.restaurant,
    this.mealType = "lunch",
  });

  Map<String, dynamic> toMap() => {
        'mealType': mealType,
        'name': name,
        'ingredients': ingredients,
        'restrictions': restrictions,
      };

  static Meal fromMap(Map<String, dynamic> m) {
    final type = m['mealType'] as String? ?? 'lunch';
    Color color;
    IconData icon;
    switch (type.toLowerCase()) {
      case 'breakfast':
        color = Colors.purple;
        icon = Icons.free_breakfast;
        break;
      case 'lunch':
        color = Colors.red;
        icon = Icons.lunch_dining;
        break;
      case 'dinner':
        color = Colors.blue;
        icon = Icons.dinner_dining;
        break;
      default:
        color = Colors.grey;
        icon = Icons.restaurant;
    }
    return Meal(
      m['name'] as String,
      List<String>.from(m['ingredients'] ?? const []),
      restrictions: List<String>.from(m['restrictions'] ?? const []),
      mealType: type,
      color: color,
      icon: icon,
    );
  }
}

DateTime normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);
DateTime weekStartOf(DateTime d) => normalizeDate(d).subtract(Duration(days: normalizeDate(d).weekday % 7));
String isoDate(DateTime d) => normalizeDate(d).toIso8601String();
String isoWeek(DateTime d) => weekStartOf(d).toIso8601String();
String mealPlanDocId(String uid, DateTime weekStart) => '${uid}_mealplan_${isoWeek(weekStart)}';
String groceriesDocId(String uid, DateTime weekStart) => '${uid}_groceries_${isoWeek(weekStart)}';

class MealPlanRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<Map<DateTime, List<Meal>>> streamMealPlan(String uid) {
    return _db
        .collection('mealPlans')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final map = <DateTime, List<Meal>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final days = (data['days'] as Map<String, dynamic>? ?? {});
        days.forEach((dateStr, mealsList) {
          //print("Firestore day key: $dateStr → meals count ${(mealsList as List).length}");

          //  Parse the ISO string back into a DateTime
          final date = DateTime.parse(dateStr); // "2025-11-22T00:00:00.000"
          final normalized = normalizeDate(date); // ensures midnight
          final meals = (mealsList as List<dynamic>)
              .map((e) => Meal.fromMap(Map<String, dynamic>.from(e)))
              .toList();
          map[normalized] = meals;
        });
      }
      return map;
    });
  }

  Future<void> addMeal({
    required DateTime date,
    required Meal meal,
    required String mealType,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception("User not signed in");
    }

    final dayKey = normalizeDate(date).toIso8601String(); 
    final weekStart = weekStartOf(date);

  //print("Saved meal for $dayKey under doc ${docRef.id}");

    await docRef.set({
      'userId': uid,
      'weekStart': isoWeek(weekStart),
      'days': {
        dayKey: FieldValue.arrayUnion([
          {...meal.toMap(), 'mealType': mealType},
        ]),
      },
    }, SetOptions(merge: true));
  }

  Future<void> deleteMeal({
    required String uid,
    required DateTime date,
    required Meal meal,
  }) async {
    final dayKey = isoDate(date);
    final docRef = _db.collection('mealPlans').doc(mealPlanDocId(uid, date));
    final mealMap = meal.toMap();
    await docRef.set({
      'days.$dayKey': FieldValue.arrayRemove([mealMap]),
    }, SetOptions(merge: true));
  }

  Future<void> addGroceries({
    required DateTime date,
    required List<String> ingredients,
    String listName = '', 
    bool initialIsManual = false,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("User not signed in");

    final weekKey = isoWeek(date);
    final docRef = _db.collection('groceries').doc(groceriesDocId(uid, date));

    await docRef.set({
      'userId': uid,
      'weekStart': weekKey,
      'items': FieldValue.arrayUnion(ingredients),
      'listName': listName, 
      'isManual': initialIsManual,
    }, SetOptions(merge: true));
  }
  
  Future<void> addGroceryItem({
    required DateTime weekStart,
    required String item,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("User not signed in");

    final docRef = _db.collection('groceries').doc(groceriesDocId(uid, weekStart));

    await docRef.update({
      'items': FieldValue.arrayUnion([item]),
    });
  }

  Stream<Map<String, dynamic>> streamGroceriesDoc(String uid, DateTime weekStart) {
    return _db.collection('groceries').doc(groceriesDocId(uid, weekStart)).snapshots().map((doc) {
      if (!doc.exists) {
        return {
          'items': <String>[],
          'checked': <String, bool>{},
          'userId': uid,
          'weekStart': isoWeek(weekStart),
          'listName': null,
          'isManual': false,
        };
      }
      final data = doc.data()!;
      return {
        'items': List<String>.from(data['items'] ?? const []),
        'checked': Map<String, bool>.from(data['checked'] ?? const {}),
        'userId': data['userId'] ?? uid,
        'weekStart': data['weekStart'] ?? isoWeek(weekStart),
        'isManual': data['isManual'] ?? false, 
        'listName': data['listName'] as String?, 
      };
    });
  }

  Future<void> toggleGroceryChecked({
    required String uid,
    required DateTime weekStart,
    required String item,
    required bool newValue,
  }) async {
    final docRef = _db.collection('groceries').doc(groceriesDocId(uid, weekStart));
    await docRef.set({
      'checked': {item: newValue},
    }, SetOptions(merge: true));
  }

  Future<void> deleteGroceryItem({
    required String uid,
    required DateTime weekStart,
    required String item,
  }) async {
    final docRef = _db.collection('groceries').doc(groceriesDocId(uid, weekStart));

    await docRef.update({
      'items': FieldValue.arrayRemove([item]),
    });

    await docRef.set({
      'checked': {item: FieldValue.delete()},
    }, SetOptions(merge: true));
  }

  Future<void> editGroceryItem({
    required String uid,
    required DateTime weekStart,
    required String oldItem,
    required String newItem,
  }) async {
    final docRef = _db.collection('groceries').doc(groceriesDocId(uid, weekStart));
    await docRef.update({
      'items': FieldValue.arrayRemove([oldItem]),
    });

    await docRef.update({
      'items': FieldValue.arrayUnion([newItem]),
    });

    final docSnapshot = await docRef.get();
    final data = docSnapshot.data();
    final checkedMap = Map<String, bool>.from(data?['checked'] ?? const {});
    final wasChecked = checkedMap[oldItem] ?? false;

     await docRef.set({
      'checked': {oldItem: FieldValue.delete()},
    }, SetOptions(merge: true));

    if (wasChecked) {
      await docRef.set({
        'checked': {newItem: true},
      }, SetOptions(merge: true));
    }
  }

  Future<void> hardDeleteWeek({
    required String uid,
    required DateTime weekStart,
  }) async {
    await _db.collection('groceries').doc(groceriesDocId(uid, weekStart)).delete();
  }
}
//////////  GroceryPage 
class GroceryPage extends StatelessWidget {
  final VoidCallback onBackToMealPrep;

  const GroceryPage({super.key, required this.onBackToMealPrep});

  Future<void> _showAddItemDialog(
    BuildContext context,
    MealPlanRepo repo,
    DateTime weekStart,
  ) async {
    final TextEditingController controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Add New Item"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Enter item name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              onPressed: () async {
                final newItem = controller.text.trim();
                if (newItem.isNotEmpty) {
                  Navigator.of(dialogContext).pop();
                  try {
                    await repo.addGroceryItem(weekStart: weekStart, item: newItem);
                    if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Added '$newItem'")),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error adding item: $e")),
                      );
                    }
                  }
                } else {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _showItemOptions(
    BuildContext context,
    MealPlanRepo repo,
    String uid,
    DateTime weekStart,
    String item,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Manage '$item'"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Item'),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _showEditDialog(context, repo, uid, weekStart, item);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Item'),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _showDeleteConfirmation(context, repo, uid, weekStart, item);
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    MealPlanRepo repo,
    String uid,
    DateTime weekStart,
    String item,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) { 
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete '$item' from the list?"),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await repo.deleteGroceryItem(uid: uid, weekStart: weekStart, item: item);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Deleted '$item'")),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error deleting item: $e")),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    MealPlanRepo repo,
    String uid,
    DateTime weekStart,
    String oldItem,
  ) async {
    final TextEditingController controller = TextEditingController(text: oldItem);
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) { 
        return AlertDialog(
          title: const Text("Edit Grocery Item"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Enter new item name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              onPressed: () async {
                final newItem = controller.text.trim();
                if (newItem.isNotEmpty && newItem != oldItem) {
                  Navigator.of(dialogContext).pop();
                  try {
                    await repo.editGroceryItem(
                        uid: uid, weekStart: weekStart, oldItem: oldItem, newItem: newItem);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Edited '$oldItem' to '$newItem'")),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error editing item: $e")),
                      );
                    }
                  }
                } else {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showManualAddDialog(BuildContext context, String uid) async {
    DateTime selectedDate = DateTime.now(); 
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) { 
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Create Grocery List"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("List Name:"),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: "Enter list name",
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(
                        "Week starting: ${weekStartOf(selectedDate).month}/${weekStartOf(selectedDate).day}/${weekStartOf(selectedDate).year}"),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  final listName = nameController.text.trim();
                  
                  if (listName.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a list name.')),
                      );
                    }
                    return; 
                  }
                  
                  const items = <String>[]; 

                  Navigator.pop(dialogContext);
                  
                  await MealPlanRepo().addGroceries(
                    date: selectedDate,
                    ingredients: items, 
                    listName: listName, 
                    initialIsManual: true, 
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Empty grocery list created!')),
                    );
                  }
                },
                child: const Text("Create List"),
              ),
            ],
          );
        });
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Grocery List"),
          backgroundColor: const Color(0xFF5aa454),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBackToMealPrep),
        ),
        body: const Center(child: Text("Please sign in.")),
      );
    }

    final repo = MealPlanRepo();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Grocery List"),
        backgroundColor: const Color(0xFF5aa454),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBackToMealPrep),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text("Create My Grocery List"),
                    onPressed: () => _showManualAddDialog(context, user.uid),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groceries')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                      child: Text("No groceries yet. Add meals or create a new list."));
                }

                final weeks = docs.map((d) => DateTime.parse(d['weekStart'] as String)).toList()
                  ..sort((a, b) => b.compareTo(a));
                final now = DateTime.now();
                final currentWeekStart = weekStartOf(now);

                return ListView.builder(
                  itemCount: weeks.length,
                  itemBuilder: (context, index) {
                    final weekStart = weeks[index];
                    return StreamBuilder<Map<String, dynamic>>(
                      stream: repo.streamGroceriesDoc(user.uid, weekStart),
                      builder: (context, grocSnap) {
                        if (!grocSnap.hasData) return const SizedBox.shrink();
                        final data = grocSnap.data!;
                        
                        final items = List<String>.from(data['items'] ?? const [])..sort();
                        final checkedMap = Map<String, bool>.from(data['checked'] ?? const {});
                        final isCurrentWeek = weekStart.isAtSameMomentAs(currentWeekStart);
                        final checkedCount = items.where((item) => checkedMap[item] ?? false).length;
                        final isManual = data['isManual'] as bool? ?? false;
                        final listName = data['listName'] as String?; 

                        final title = listName != null && listName.isNotEmpty
                            ? listName
                            :"Week of ${weekStart.month}/${weekStart.day}/${weekStart.year}";


                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: ExpansionTile(
                            initiallyExpanded: isCurrentWeek,
                            title: Text(title), 
                            subtitle: listName != null && listName.isNotEmpty
                                ? Text("Week of ${weekStart.month}/${weekStart.day}/${weekStart.year}")
                                : null ,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Delete List"),
                                    content: Text(
                                        "Are you sure you want to delete the list **$title**?"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                      ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await repo.hardDeleteWeek(uid: user.uid, weekStart: weekStart);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Grocery list deleted.')),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        child: const Text("Delete ", style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            children: [
                              // Add New Item Button
                              ListTile(
                                leading: const Icon(Icons.add_circle, color: Colors.green),
                                title: const Text("Add New Item"),
                                onTap: () => _showAddItemDialog(context, repo, weekStart),
                              ),
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              // Grocery Items
                              for (final item in items)
                                ListTile(
                                  leading: Checkbox(
                                    value: checkedMap[item] ?? false,
                                    onChanged: (bool? newVal) async {
                                      await repo.toggleGroceryChecked(
                                        uid: user.uid,
                                        weekStart: weekStart,
                                        item: item,
                                        newValue: newVal ?? false,
                                      );
                                    },
                                    activeColor: Colors.green,
                                  ),
                                  title: Text(
                                    item,
                                    style: TextStyle(
                                      decoration: (checkedMap[item] ?? false) ? TextDecoration.lineThrough : null,
                                      color: (checkedMap[item] ?? false) ? Colors.grey : Colors.black,
                                    ),
                                  ),
                                  onTap: () {
                                    repo.toggleGroceryChecked(
                                      uid: user.uid,
                                      weekStart: weekStart,
                                      item: item,
                                      newValue: !(checkedMap[item] ?? false),
                                    );
                                  },
                                  trailing: IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () => _showItemOptions(
                                      context,
                                      repo,
                                      user.uid,
                                      weekStart,
                                      item,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
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
}

// MealPlannerPage 
class MealPlannerPage extends StatefulWidget {
  final Set<String> excludedIngredients;
  final Set<Meal>? savedRecipes;
  final void Function(Meal meal)? onToggleSaveRecipe;

  const MealPlannerPage({
    super.key,
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

  final repo = MealPlanRepo();

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
          SimpleDialogOption(onPressed: () => Navigator.pop(context, "breakfast"), child: const Text("Breakfast")),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, "lunch"), child: const Text("Lunch")),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, "dinner"), child: const Text("Dinner")),
        ],
      ),
    );

    if (selected != null) await _addMeal(date, selected);
  }

  Future<void> _addMeal(DateTime date, String mealType) async {
    final meal = await Navigator.push<Meal?>(
      context,
      MaterialPageRoute(
        builder: (_) => RecipePage(
          excludedIngredients: widget.excludedIngredients,
          mealType: mealType,
        ),
      ),
    );

    if (meal != null) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("User not signed in");
      }
      await repo.addMeal(date: date, meal: meal, mealType: mealType);
      await repo.addGroceries(date: date, ingredients: meal.ingredients);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal added to plan and groceries updated'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _deleteMeal(DateTime date, Meal meal) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await repo.deleteMeal(uid: user.uid, date: date, meal: meal);
  }

  void _showMealIngredientSubstitution(Meal meal, DateTime date, Map<DateTime, List<Meal>> mealPlan) {
    // Convert Meal to Recipe for the substitution page
    final recipe = Recipe(
      name: meal.name,
      imageUrl: '', // Meals don't have images
      hashtags: meal.restrictions.map((r) => '#$r').toList(),
      ingredients: meal.ingredients,
      author: 'Meal Prep',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IngredientSubstitutionPage(recipe: recipe),
      ),
    );
  }

  void _showMeals(DateTime date, Map<DateTime, List<Meal>> mealPlan) {
    final meals = mealPlan[normalizeDate(date)] ?? [];

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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF479E36)),
                              tooltip: 'Modify Ingredients',
                              onPressed: () {
                                Navigator.pop(context);
                                _showMealIngredientSubstitution(meal, date, mealPlan);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _deleteMeal(date, meal);
                                Navigator.pop(context);
                                _showMeals(date, mealPlan);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showMealIngredientSubstitution(meal, date, mealPlan);
                        },
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

  Widget _buildMonthGrid(Map<DateTime, List<Meal>> mealPlan) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final offset = firstDay.weekday % 7;
    final totalDays = lastDay.day;
    final totalCells = ((offset + totalDays) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < offset || index >= offset + totalDays) return const SizedBox();

        final day = index - offset + 1;
        final date = DateTime(_currentMonth.year, _currentMonth.month, day);
        final meals = mealPlan[normalizeDate(date)] ?? [];
        //print("Looking up ${normalizeDate(date)} → found ${meals.length} meals");


        return GestureDetector(
          onTap: () => _showMeals(date, mealPlan),
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
                    Wrap(
                      spacing: 2,
                      children: meals.map((meal) {
                        Color dotColor;
                        switch (meal.mealType.toLowerCase()) {
                          case 'breakfast':
                            dotColor = Colors.purple;
                            break;
                          case 'lunch':
                            dotColor = Colors.red;
                            break;
                          case 'dinner':
                            dotColor = Colors.blue;
                            break;
                          default:
                            dotColor = Colors.grey;
                        }
                        return Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dotColor,
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekRow(Map<DateTime, List<Meal>> mealPlan) {
    final week = weekStartOf(_selectedDate);

    return Row(
      children: List.generate(7, (i) {
        final date = week.add(Duration(days: i));
        final meals = mealPlan[normalizeDate(date)] ?? [];
        //print("Week cell ${normalizeDate(date)} → ${meals.length} meals");


        return Expanded(
          child: GestureDetector(
            onTap: () => _showMeals(date, mealPlan),
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
                    Wrap(
                      spacing: 2,
                      children: meals.map((meal) {
                        Color dotColor;
                        switch (meal.mealType.toLowerCase()) {
                          case 'breakfast':
                            dotColor = Colors.purple;
                            break;
                          case 'lunch':
                            dotColor = Colors.red;
                            break;
                          case 'dinner':
                            dotColor = Colors.blue;
                            break;
                          default:
                            dotColor = Colors.grey;
                        }
                        return Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dotColor,
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWeekMeals(Map<DateTime, List<Meal>> mealPlan) {
    final week = weekStartOf(_selectedDate);

    final Map<String, List<Meal>> grouped = {
      "breakfast": [],
      "lunch": [],
      "dinner": [],
    };

    for (int i = 0; i < 7; i++) {
      final date = week.add(Duration(days: i));
      final meals = mealPlan[normalizeDate(date)] ?? [];
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
          ...grouped["breakfast"]!.map((m) => Text("• ${m.name}  (${m.ingredients.join(", ")})")),
        ],
        if (grouped["lunch"]!.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text("Lunch", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...grouped["lunch"]!.map((m) => Text("• ${m.name}  (${m.ingredients.join(", ")})")),
        ],
        if (grouped["dinner"]!.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text("Dinner", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...grouped["dinner"]!.map((m) => Text("• ${m.name}  (${m.ingredients.join(", ")})")),
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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Meal Planner"),
          backgroundColor: const Color(0xFF5aa454),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: Text("Please sign in.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meal Planner"),
        backgroundColor: const Color(0xFF5aa454),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: "Grocery List",
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroceryPage(
                    onBackToMealPrep: () => Navigator.pop(context),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Map<DateTime, List<Meal>>>(
        stream: repo.streamMealPlan(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final mealPlan = snapshot.data!;
          //print("MealPlan keys: ${mealPlan.keys}"); //debug


          return Center(
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
                            : "Week of ${weekStartOf(_selectedDate).month}/${weekStartOf(_selectedDate).day}",
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
                  _isMonthView ? _buildMonthGrid(mealPlan) : _buildWeekRow(mealPlan),
                  const SizedBox(height: 16),
                  if (!_isMonthView) _buildWeekMeals(mealPlan),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add Meal"),
                    onPressed: () => _pickMealType(_isMonthView ? DateTime.now() : _selectedDate),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
class RecipePage extends StatelessWidget {
  final Set<String> excludedIngredients;
  final String mealType;

  const RecipePage({
    super.key,
    required this.excludedIngredients,
    required this.mealType,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Pick a Recipe"),
          backgroundColor: const Color(0xFF5aa454),
        ),
        body: const Center(child: Text("Please sign in.")),
      );
    }

    final query = FirebaseFirestore.instance.collection('recipes').snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick a Recipe"),
        backgroundColor: const Color(0xFF5aa454),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          final meals = <Meal>[];

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] as String?) ?? 'Untitled';
            final ingredients = List<String>.from(data['ingredients'] ?? const []);
            final blocked = ingredients.any((ing) => excludedIngredients.contains(ing));
            if (blocked) continue;

            meals.add(Meal(
              name,
              ingredients,
              restrictions: List<String>.from(data['restrictions'] ?? const []),
              color: Colors.green,
              icon: Icons.restaurant,
              mealType: this.mealType, 
            ));
          }

          if (meals.isEmpty) {
            return const Center(child: Text("No available recipes with current filters."));
          }

          return ListView(
            children: meals.map((meal) {
              return Card(
                child: ListTile(
                  leading: Icon(meal.icon, color: meal.color),
                  title: Text(meal.name),
                  subtitle: Text("Ingredients: ${meal.ingredients.join(", ")}"),
                  onTap: () => Navigator.pop(context, meal),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

Future<void> seedExampleRecipes() async {
  final recipes = [
    {
      'name': 'Chicken Stir Fry',
      'ingredients': ['Chicken', 'Bell Pepper', 'Soy Sauce', 'Garlic'],
      'restrictions': ['Peanut Allergy Safe'],
      'isShared': true, 
    },
    {
      'name': 'Veggie Pasta',
      'ingredients': ['Pasta', 'Tomato', 'Basil', 'Olive Oil'],
      'restrictions': ['Vegetarian'],
      'isShared': true,
    },
    {
      'name': 'Salmon Bowl',
      'ingredients': ['Salmon', 'Rice', 'Avocado', 'Sesame'],
      'restrictions': ['Contains Fish'],
      'isShared': true,
    },
    {
      'name': 'Beef Tacos',
      'ingredients': ['Beef', 'Tortilla', 'Onion', 'Cilantro'],
      'restrictions': ['Contains Gluten'],
      'isShared': true,
    },
    {
      'name': 'Quinoa Salad',
      'ingredients': ['Quinoa', 'Cucumber', 'Tomato', 'Feta'],
      'restrictions': ['Vegetarian'],
      'isShared': true,
    },
  ];

  for (final recipe in recipes) {
    final docId = (recipe['name'] as String).toLowerCase().replaceAll(' ', '_');
    await FirebaseFirestore.instance
        .collection('recipes')
        .doc(docId)
        .set(recipe, SetOptions(merge: true));
  }
}