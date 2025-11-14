import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;
  const Background({
   required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
        Size size = MediaQuery.of(context).size; //height and width of screen
    return Container(
    height: size.height,
    width: double.infinity,
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned(
          top: size.height * 0.3,
          child: Image.asset(
            "assets/images/Homepage.svg.png", 
            width: size.width,
            height: size.height * 0.3,
            fit:BoxFit.cover, //fix the sizing 
            ),
          ),
        Positioned(
          top: 0,
          child: Image.asset(
          "assets/images/hoPG.svg.png",
          width: size.width,
          height: size.height * 0.3,
          fit:BoxFit.cover,
          ),
        ),
        Positioned(
          right: -90,
          top: size.height * 0.2,
          child: Image.asset(
            "assets/images/spoon.svg.png",
            width: size.width,
            height: size.height * 0.2,
          ),
        ),
        Positioned(
          top: size.height * 0.45,
          left: 0,
          right: 0,
          child: Text(
            "Byte-to-Bite",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 255, 255, 255),
              //fontFamily: 'Jersey10',
            ),
          ),
        ),
        child,
      ],
     ),
    );
  }
}