import 'package:flutter/material.dart';
import 'package:byte_to_bite/Pages/Welcome/welcome_page.dart';
import 'package:byte_to_bite/Pages/WelcomeUser/welcomeuser_page.dart';

class WelcomeBackPage extends StatelessWidget {
	final String email;

	const WelcomeBackPage({super.key, required this.email});

	@override
	Widget build(BuildContext context) {
		final size = MediaQuery.of(context).size;
		final String username = email.contains('@') ? email.split('@').first : (email.isNotEmpty ? email : 'Guest');

		return Scaffold(
			body: Center(
				child: Container(
					width: size.width * 0.8,
					padding: const EdgeInsets.all(20),
					decoration: BoxDecoration(
						color: const Color(0xFF479E36),
						borderRadius: BorderRadius.circular(12),
						boxShadow: const [
							BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 8),
						],
					),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							const Text(
								'Welcome Back!',
								style: TextStyle(
									color: Colors.white,
									fontSize: 24,
									fontWeight: FontWeight.bold,
								),
							),
							const SizedBox(height: 10),
							Text(
								username,
								style: const TextStyle(color: Colors.white70, fontSize: 16),
								textAlign: TextAlign.center,
							),
						const SizedBox(height: 18),
						SizedBox(
							width: size.width * 0.6,
							child: ElevatedButton(
								onPressed: () {
								Navigator.push(
									context,
									MaterialPageRoute(
										builder: (context) => WelcomeUserPage(
												firstName: username,
											),
										),
									);
								},
								style: ElevatedButton.styleFrom(
									padding: const EdgeInsets.symmetric(vertical: 14),
								),
								child: const Text('Customize your experience'),
							),
						),
						const SizedBox(height: 10),
							const Text(
								'Welcome back to meal prepping',
								style: TextStyle(
									color: Colors.white,
									fontSize: 16,
								),
								textAlign: TextAlign.center,
							),
						],
					),
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

