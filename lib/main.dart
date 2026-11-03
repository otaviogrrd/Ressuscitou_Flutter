import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:get/get.dart";
import "helpers/global.dart";
import "pages/splash.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await globals.inicial();
  runApp(MainPage());
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      defaultTransition: Transition.cupertino,
      debugShowCheckedModeBanner: false,
      title: "Ressuscitou",
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('pt', 'BR')],
      themeMode: ThemeMode.system,
      darkTheme: ThemeData(
          useMaterial3: false,
          scaffoldBackgroundColor: Colors.grey.shade900,
          colorScheme: ColorScheme.dark(
            primary: globals.lightRedDarkTheme,
            primaryContainer: Colors.grey.shade900,
            secondary: Colors.grey.shade700,
            onPrimary: Colors.black,
            onSecondary: Colors.white,
            onSurface: Colors.white54,
          ),
          inputDecorationTheme: InputDecorationThemeData(
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
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: globals.darkRed,
        colorScheme: ColorScheme.light(
          primary: globals.darkRed,
          primaryContainer: globals.darkRedShadow,
          secondary: Colors.grey.shade200,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.black26,
        ),
        inputDecorationTheme: InputDecorationThemeData(
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
      // AppBar handles the top inset; protect page controls from Android's
      // gesture area and three-button navigation in edge-to-edge mode.
      builder: (context, child) => SafeArea(
        top: false,
        child: child ?? const SizedBox.shrink(),
      ),
      home: Splash(),
    );
  }
}
