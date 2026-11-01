library globals;

import 'dart:convert';
import 'dart:math';

import "package:flutter/material.dart";
import "package:intl/intl.dart";
import 'package:package_info_plus/package_info_plus.dart';
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
  late SharedPreferences prefs;
  late PackageInfo packInfo;
  double nrPopups = 0;
  bool tablet = false;

  Future<void> inicial() async {
    prefs = await SharedPreferences.getInstance();
    packInfo = await PackageInfo.fromPlatform();
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
    return globals.prefs.getBool("tablet") ?? isTablet;
  }
  return isTablet;
}

void snackBar(BuildContext? cont, String str, {String? title}) {
  if (cont == null || !cont.mounted) return;
  ScaffoldMessenger.maybeOf(cont)?.showSnackBar(SnackBar(
    content: Text(title == null ? str : "$title\n$str"),
    duration: const Duration(seconds: 3),
    behavior: SnackBarBehavior.floating,
  ));
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
      return Colors.grey.shade200;
  }
}

String getPrettyJSONString(jsonObject) {
  var encoder = new JsonEncoder.withIndent("     ");
  return encoder.convert(jsonObject);
}
