import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:get/get.dart";
import "package:ressuscitou/helpers/global.dart";
import "package:ressuscitou/pages/splash.dart";

void main() => runApp(MainPage());

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    globals.inicial();
    return GetMaterialApp(
      defaultTransition: Transition.cupertino,
      debugShowCheckedModeBanner: false,
      title: "Ressuscitou",
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('pt', 'BR')],
      themeMode: ThemeMode.system,
      darkTheme: ThemeData(
          scaffoldBackgroundColor: Colors.grey.shade900,
          colorScheme: ColorScheme.dark(
            primary: globals.lightRedDarkTheme,
            primaryVariant: Colors.grey.shade900,
            secondary: Colors.grey[700],
            onPrimary: Colors.black,
            onSecondary: Colors.white,
            onBackground: Colors.white54,
          ),
          inputDecorationTheme: InputDecorationTheme(
              filled: true,
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                gapPadding: 10,
                borderRadius: BorderRadius.circular(2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: globals.lightRedDarkTheme),
                gapPadding: 10,
                borderRadius: BorderRadius.circular(2),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: globals.lightRedDarkTheme),
                gapPadding: 10,
                borderRadius: BorderRadius.circular(2),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                gapPadding: 10,
                borderRadius: BorderRadius.circular(2),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: globals.lightRedDarkTheme),
                gapPadding: 10,
                borderRadius: BorderRadius.circular(2),
              ))),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: globals.darkRed,
        colorScheme: ColorScheme.light(
          primary: globals.darkRed,
          primaryVariant: globals.darkRedShadow,
          secondary: Colors.grey[200],
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onBackground: Colors.black26,
        ),
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
