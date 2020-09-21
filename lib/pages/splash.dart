import "dart:async";

import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:ressuscitou/model/canto.dart";
import "package:ressuscitou/pages/home.dart";

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  initState() {
    getCantos();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Image.asset("assets/img/logo.png"),
          ),
        ),
      ),
    );
  }

  getCantos() async {
    await CantoService().getCantos().then((List<Canto> cantos) {
      Timer(Duration(seconds: 1), () => Get.off(HomePage(selectable: false,)));
    });
  }
}
