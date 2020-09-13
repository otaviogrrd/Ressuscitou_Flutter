library globals;

import "package:flushbar/flushbar.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:ressuscitou/model/canto.dart";
import "package:shared_preferences/shared_preferences.dart";

var globals = new Globals();


class Globals {
  List<Canto> cantosGlobal = [];
  List<Canto> listaGlobal = [];
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

  SharedPreferences prefs;
  void inicial() {
    SharedPreferences.getInstance().then((value) => this.prefs = value);
  }
}

Color hexToColor(String code) {
  return new Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
}


snackBar(BuildContext cont, String str, {String title}) {
  Flushbar(
    title: title,
    messageText: Padding(
      padding: EdgeInsets.all(10),
      child: Text(
        str,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      ),
    ),
    margin: EdgeInsets.all(20),
    duration: Duration(seconds: 3),
    borderRadius: 3,
    backgroundGradient: LinearGradient(
      begin: FractionalOffset.bottomCenter,
      end: FractionalOffset.topCenter,
      colors: [Colors.white, globals.lightRed],
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
}