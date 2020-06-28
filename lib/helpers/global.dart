library globals;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

var globals = new Globals();


class Globals {
  SharedPreferences prefs;
  Color lightRed = hexToColor("#af282f");
  Color darkRed = hexToColor("#650000");
  Color darkRedShadow = hexToColor("#2d0000");
  double fontSizeBig = 20.0;
  double fontSizeNormal = 17.0;
  List<String> escalaTmp = ["zerofiller","@01","@02","@03","@04","@05","@06","@07","@08","@09","@10","@11","@12"];
  List<String> escalaEuropeia = ["zerofiller","Do","Do#","Re","Mib","Mi","Fa","Fa#","Sol","Sol#","La","Sib","Si","Do","Do#","Re","Mib","Mi","Fa","Fa#","Sol","Sol#","La","Sib","Si"];
  List<String> escalaAmericana = ["zerofiller", "C", "C#", "D", "Eb", "E", "F", "F#", "G", "G#", "A", "Bb", "B", "C", "C#", "D", "Eb", "E", "F", "F#", "G", "G#", "A", "Bb", "B"];
  List<String> escalaMenos = ["C-", "C#-", "D-", "Eb-", "E-", "F-", "F#-", "G-", "G#-", "A-", "Bb-", "B-"];
  List<String> escalaMenor = ["Cm", "C#m", "Dm", "Ebm", "Em", "Fm", "F#m", "Gm", "G#m", "Am", "Bbm", "Bm"];

  void inicial() {
    SharedPreferences.getInstance().then((value) => this.prefs = value);
  }
}

Color hexToColor(String code) {
  return new Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
}

snackBar(String str) {
  Get.rawSnackbar(
    message: str,
    backgroundColor: Colors.black38,
  );
}
