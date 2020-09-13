import "dart:async";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:ressuscitou/helpers/global.dart";
import "package:ressuscitou/model/canto.dart";
import "package:ressuscitou/pages/home.dart";

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  bool loaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: CantoService().getCantos(),
          builder: (BuildContext cont, AsyncSnapshot<List<Canto>> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return getLogo();
              case ConnectionState.done:
                Timer(Duration(seconds: 1), () => goToHome());
                return getLogo();
              default:
                if (snapshot.hasError) snackBar(Get.overlayContext, "Erro: ${snapshot.error}");
                return getLogo();
            }
          }),
    );
  }

  getLogo() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: Colors.white,
      child: Center(
          child: Padding(
        padding: EdgeInsets.all(30),
        child: Image.asset("assets/img/logo.png"),
      )),
    );
  }

  goToHome() {
    if (!loaded) {
      Get.off(HomePage()); //, transition: Transition.fade, duration: Duration(seconds: 1));
      loaded = true;
    }
  }
}
