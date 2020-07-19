import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ressuscitou/pages/splash.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'package:ressuscitou/helpers/global.dart';

void main() => runApp(MainPage());

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    globals.inicial();
    return GetMaterialApp(
      defaultTransition: Transition.cupertino,
      debugShowCheckedModeBanner: false,
      title: 'Ressuscitou',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('pt'),
      ],
      theme: ThemeData(
        backgroundColor: Colors.white,
        primaryColor: globals.darkRed,
        accentColor: globals.lightRed,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.all(10),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
            gapPadding: 10,
            borderRadius: BorderRadius.circular(2),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: globals.darkRed),
            gapPadding: 10,
            borderRadius: BorderRadius.circular(2),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: globals.darkRed),
            gapPadding: 10,
            borderRadius: BorderRadius.circular(2),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: globals.darkRed),
            gapPadding: 10,
            borderRadius: BorderRadius.circular(2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: globals.darkRed),
            gapPadding: 10,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      home: Splash(),
    );
  }
}
