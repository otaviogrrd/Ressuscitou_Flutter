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
    return GetMaterialApp(
      defaultTransition: Transition.cupertino,
      debugShowCheckedModeBanner: false,
      title: 'Spaco',
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
        cursorColor: Colors.black,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
         EdgeInsets.all(10),
//          disabledBorder: OutlineInputBorder(
//              borderSide:BorderSide(color: globals.darkRed),
//              gapPadding: 10),
//          enabledBorder: OutlineInputBorder(
//              borderSide:BorderSide(color: globals.darkRed),
//              gapPadding: 10),
//          focusedBorder: OutlineInputBorder(
//              borderSide:BorderSide(color: globals.darkRed),
//              gapPadding: 10),
//          errorBorder: OutlineInputBorder(
//              borderSide:BorderSide(color: globals.darkRed),
//              gapPadding: 10),
//          focusedErrorBorder: OutlineInputBorder(
//              borderSide:BorderSide(color: globals.darkRed),
//              gapPadding: 10),
        ),
      ),
      home: Splash(),
    );
  }
}