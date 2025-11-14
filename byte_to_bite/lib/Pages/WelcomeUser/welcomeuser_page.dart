import 'package:flutter/material.dart';
import 'package:byte_to_bite/Pages/Welcome/welcome_page.dart';
import 'package:byte_to_bite/main.dart';


class WelcomeUserPage extends StatefulWidget {
  final String firstName;
  final String lastName;

  const WelcomeUserPage({
    super.key,
    this.firstName = 'User',
    this.lastName = '',
  });

  @override
  State<WelcomeUserPage> createState() => _WelcomeUserPageState();
}

class _WelcomeUserPageState extends State<WelcomeUserPage> {
  int _currentPage = 0;

  // Page 1
  // Page 2
  final List<String> goals = ['Weight Loss', 'Muscle Gain', 'Better Health', 'Cook More'];
  final Map<String, bool> selectedGoals = {};

  // Page 3
  final List<String> dietaryRestrictions = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Nut-Free',
    'Kosher'
  ];
  final Map<String, bool> selectedRestrictions = {};

  // Page 4
  final List<String> foodsLike = [
    'Pasta',
    'Chicken',
    'Vegetables',
    'Seafood',
    'Rice',
    'Mexican'
  ];
  final Map<String, bool> selectedFoodsLike = {};

  // Page 5
  final List<String> foodsDislike = [
    'Liver',
    'Mushrooms',
    'Spicy Food',
    'Raw Fish',
    'Bitter Greens',
    'Offal'
  ];
  final Map<String, bool> selectedFoodsDislike = {};

  // Page 6
  final List<String> cookingLevels = ['Beginner', 'Intermediate', 'Advanced', 'Chef'];
  final Map<String, bool> selectedCookingLevel = {};

  @override
  void initState() {
    super.initState();
    
    for (var goal in goals) selectedGoals[goal] = false;
    for (var restriction in dietaryRestrictions) selectedRestrictions[restriction] = false;
    for (var food in foodsLike) selectedFoodsLike[food] = false;
    for (var food in foodsDislike) selectedFoodsDislike[food] = false;
    for (var level in cookingLevels) selectedCookingLevel[level] = false;
  }

  Widget _buildCheckboxPage(String title, List<String> items, Map<String, bool> selectedMap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: selectedMap[item] ?? false,
                onChanged: (value) {
                  setState(() {
                    selectedMap[item] = value ?? false;
                  });
                },
                activeColor: Colors.white,
                checkColor: const Color(0xFF479E36),
              ),
              Text(
                item,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildPage() {
    switch (_currentPage) {
      case 0:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Your Profile Setup!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Let\'s customize your experience',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case 1:
        return _buildCheckboxPage('What are your goals?', goals, selectedGoals);
      case 2:
        return _buildCheckboxPage('Dietary Restrictions', dietaryRestrictions, selectedRestrictions);
      case 3:
        return _buildCheckboxPage('Foods You Like', foodsLike, selectedFoodsLike);
      case 4:
        return _buildCheckboxPage('Foods You Don\'t Like', foodsDislike, selectedFoodsDislike);
      case 5:
      return Column(
        children: [
          _buildCheckboxPage('Cooking Level', cookingLevels, selectedCookingLevel),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DietaryApp()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF479E36),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Finish Setup'),
          ),
        ],
      );
      default:
        return SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    String fullName =
        widget.lastName.isNotEmpty ? '${widget.firstName} ${widget.lastName}' : widget.firstName;
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Image.asset(
                    'assets/images/welcomePage.jpg',
                    width: size.width,
                    height: size.height * 0.30,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 150,
                  child: Text(
                    'Welcome, $fullName!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            Container(
              width: size.width * 0.8,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF479E36),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPage(),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_left, color: Colors.white, size: 28),
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      Text(
                        '${_currentPage + 1}/6',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_right, color: Colors.white, size: 28),
                        onPressed: _currentPage < 5
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WelcomePage()),
            );
          }
          // nav bar icons that aren't home do nothing for now
        },
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
}