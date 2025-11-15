import 'package:byte_to_bite/Pages/Login/login_page.dart';
import 'package:byte_to_bite/Pages/Signup/signup_page.dart';
import 'package:byte_to_bite/Pages/Welcome/components/background.dart';
import 'package:byte_to_bite/constants.dart';
import 'package:flutter/material.dart';

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size; //height and width of screen
    return Background( 
    child: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 450),  // adjust this value to move button up or down
          SizedBox(
            width: size.width * 0.6,
            child: ElevatedButton(
              onPressed: () {Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context){
                    return LoginPage();
                    },
                    ),
                    );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              ),
              child: Text(
                "LOGIN",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: size.width * 0.6,
            child: ElevatedButton(
              onPressed: () {Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context){
                    return SignUpPage();
                    },
                    ),
                    );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 41, 186, 41),
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              ),
              child: Text(
                "SIGNUP",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
        ),
    ),
      );
  }
}

