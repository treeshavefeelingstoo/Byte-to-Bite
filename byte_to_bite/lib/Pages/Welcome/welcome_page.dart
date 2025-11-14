import 'package:byte_to_bite/Pages/Welcome/components/body.dart';
import 'package:flutter/material.dart';

Widget _buildBottomNavBar(BuildContext context, int currentIndex) {
  return BottomNavigationBar(
    currentIndex: currentIndex,
    onTap: (index) {
    
    },
    backgroundColor: Colors.green[700],
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white70,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
      BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: ''),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
    ],
  );
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Body(),
      bottomNavigationBar: _buildBottomNavBar(context, 0),
    );
  }
}
