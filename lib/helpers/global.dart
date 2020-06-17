library globals;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

var globals = new Globals();

class Globals {
  Color lightRed = hexToColor("#af282f");
  Color darkRed = hexToColor("#650000");
  double fontSizeBig = 20.0;
  double fontSizeNormal = 17.0;
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
