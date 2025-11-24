import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:byte_to_bite/Pages/RecipePage/recipe_page.dart';

class AuthorPage extends StatefulWidget {
  final String userName;

  const AuthorPage({
    super.key, 
    this.userName = 'User',
  });

  @override
  State<AuthorPage> createState() => new _AuthorPageState();
}

class _AuthorPageState extends State<AuthorPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; //Current Firebase user
    return Scaffold(
      appBar: AppBar(
        title: const Text("'s Profile"),
        backgroundColor: Colors.green[700],
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecipeFeedPage()),
              );
            },
            tooltip: 'Back',
          ),
        ],
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
                child: const Text(
                  "t",//recipe.author[0],
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 60),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          //  Stats Row (Posts, Followers, Following)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('Posts', '1'),
              _buildStatColumn('Followers', '0'),
              _buildStatColumn('Following', '0'),
            ],
          ),
        ]
      )
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}