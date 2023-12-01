library globals;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import "package:flushbar/flushbar.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import 'package:package_info/package_info.dart';
import "../model/canto.dart";
import "package:shared_preferences/shared_preferences.dart";

var globals = new Globals();

class Globals {
  List<Canto> cantosGlobal = [];
  List<Canto> listaGlobal = [];
  Color lightRed = hexToColor("#af282f");
  Color lightRedDarkTheme = hexToColor("#ff6666");
  Color darkRed = hexToColor("#650000");
  Color grey = hexToColor("#88868B");
  Color darkRedShadow = hexToColor("#2d0000");
  double fontSizeBig = 20.0;
  double fontSizeNormal = 17.0;
  List<String> escalaTmp = ["zerofiller", "@01", "@02", "@03", "@04", "@05", "@06", "@07", "@08", "@09", "@10", "@11", "@12"];
  List<String> escalaEuropeia = [
    "zerofiller",
    "Do",
    "Do#",
    "Re",
    "Mib",
    "Mi",
    "Fa",
    "Fa#",
    "Sol",
    "Sol#",
    "La",
    "Sib",
    "Si",
    "Do",
    "Do#",
    "Re",
    "Mib",
    "Mi",
    "Fa",
    "Fa#",
    "Sol",
    "Sol#",
    "La",
    "Sib",
    "Si"
  ];
  List<String> escalaAmericana = [
    "zerofiller",
    "C",
    "C#",
    "D",
    "Eb",
    "E",
    "F",
    "F#",
    "G",
    "G#",
    "A",
    "Bb",
    "B",
    "C",
    "C#",
    "D",
    "Eb",
    "E",
    "F",
    "F#",
    "G",
    "G#",
    "A",
    "Bb",
    "B"
  ];
  List<String> escalaMenos = ["C-", "C#-", "D-", "Eb-", "E-", "F-", "F#-", "G-", "G#-", "A-", "Bb-", "B-"];
  List<String> escalaMenor = ["Cm", "C#m", "Dm", "Ebm", "Em", "Fm", "F#m", "Gm", "G#m", "Am", "Bbm", "Bm"];
  SharedPreferences prefs;
  PackageInfo packInfo;
  double nrPopups = 0;
  bool tablet = false;

  void inicial() {
    SharedPreferences.getInstance().then((value) => this.prefs = value);
    PackageInfo.fromPlatform().then((value) => this.packInfo = value);
  }
}

Color hexToColor(String code) {
  return new Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
}

String getDateFormatted(DateTime date) {
  var formatter = DateFormat("dd/MM/yyyy");
  return formatter.format(date);
}

bool isTablet(MediaQueryData query) {
  var size = query.size;
  var diagonal = sqrt((size.width * size.width) + (size.height * size.height));
  var isTablet = diagonal > 1100.0;
  globals.prefs.setBool("screenDiagonal", isTablet);
  if ( globals.prefs.getBool("tablet") == null ) {
    globals.prefs.setBool("tablet", isTablet);
  }else{
    return globals.prefs.getBool("tablet");
  }
  return isTablet;
}

snackBar(BuildContext cont, String str, {String title}) {
  globals.nrPopups++;
  double topMargin = (70 * globals.nrPopups);
  Flushbar(
    title: title,
    messageText: Padding(
      padding: EdgeInsets.all(10),
      child: Text(
        str,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      ),
    ),
    margin: EdgeInsets.fromLTRB(20, topMargin, 20, 0),
    duration: Duration(seconds: 3),
    borderRadius: 3,
    backgroundGradient: LinearGradient(
      begin: FractionalOffset.bottomCenter,
      end: FractionalOffset.topCenter,
      colors: [Theme.of(cont).colorScheme.secondary, globals.lightRed],
      stops: [0.9, 0.9],
    ),
    boxShadows: [
      BoxShadow(
        color: Colors.black45,
        offset: Offset(3, 3),
        blurRadius: 3,
      ),
    ],
    isDismissible: true,
    dismissDirection: FlushbarDismissDirection.HORIZONTAL,
    flushbarPosition: FlushbarPosition.TOP,
  )..show(cont);
  Timer(Duration(seconds: 3), () => globals.nrPopups--);
}

bool checkDarkMode(BuildContext context) {
  return Theme.of(context).colorScheme.primary == globals.lightRedDarkTheme;
}

getColorCateg(int categoria) {
  switch (categoria) {
    case 2:
      return Colors.blue[200];
    case 3:
      return Colors.green[200];
    case 4:
      return Colors.orange[100];
    default:
      return Colors.grey[200];
  }
}

String getPrettyJSONString(jsonObject) {
  var encoder = new JsonEncoder.withIndent("     ");
  return encoder.convert(jsonObject);
}
