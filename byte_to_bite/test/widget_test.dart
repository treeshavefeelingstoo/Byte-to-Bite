import 'package:flutter/material.dart';

void main() => runApp(const DietaryApp());

class DietaryApp extends StatelessWidget {
  const DietaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dietary Restrictions',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFE0F2E0),
      ),
      home: const AllergySelectorScreen(),
    );
  }
}

class AllergySelectorScreen extends StatefulWidget {
  const AllergySelectorScreen({super.key});

  @override
  State<AllergySelectorScreen> createState() => _AllergySelectorScreenState();
}

class _AllergySelectorScreenState extends State<AllergySelectorScreen> {
  final Map<String, List<String>> allergyOptions = {
    'Allergies': ['Oranges', 'Pears'],
    'Lactose Intolerance': ['Milk', 'Cheese'],
    'Gluten Free': ['Wheat', 'Barley'],
  };

  final Map<String, bool> selectedIngredients = {};

  @override
  void initState() {
    super.initState();
    for (var ingredient in allergyOptions.values.expand((i) => i)) {
      selectedIngredients[ingredient] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Dietary Restrictions'),
        backgroundColor: Colors.green[700],
      ),
      body: ListView(
        children: buildAllergyTiles(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green[700],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
      ),
    );
  }

  List<Widget> buildAllergyTiles() {
    return allergyOptions.entries.map((entry) {
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
                setState(() {
                  selectedIngredients[ingredient] = value ?? false;
                  debugPrint('Selected: $ingredient → ${value ?? false}');
                });
              },
            );
          }).toList(),
        ),
      );
    }).toList();
  }
}
