import 'package:flutter/material.dart';
import 'package:byte_to_bite/Pages/Welcome/welcome_page.dart';
import 'package:byte_to_bite/constants.dart';

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
      home: WelcomePage(),
       );
  }
}

