import 'package:flutter/material.dart';
import 'package:ressuscitou/helpers/global.dart';
import 'package:splashscreen/splashscreen.dart';

import 'home.dart';

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      seconds: 2,
      navigateAfterSeconds: HomePage(),
      image: Image.asset("assets/img/logo.png"),
      backgroundColor: Colors.white,
      photoSize: 125,
      loaderColor: globals.darkRed,
    );
  }
}
