import 'package:byte_to_bite/Pages/Welcome/components/body.dart';
import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback? onContinue;
  const WelcomePage({super.key, this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Body(),
    );
  }
}
