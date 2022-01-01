import 'dart:ui';

import 'package:flutter/material.dart';

class Utils {
  static Color colorFromHex(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor; // FF as the opacity value if you don't add it.
    }
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  static Color getYellowColor() {
    return colorFromHex('#FFEBA3');
  }

  static Color getPrimaryColor() {
    return colorFromHex('#5D54C1');
  }

  static Color getBGColor() {
    return colorFromHex('#FFFFFF');
  }

  static Color getCardColor() {
    return colorFromHex('#F7F7FD');
  }

  static Color getAccentColor() {
    return colorFromHex('#FFEBA3');
  }

  static Color getWhiteColor() {
    return colorFromHex('#FFFFFF');
  }

  static Color getTextColor() {
    return colorFromHex('#FFFFFF');
  }

  static Color getWhiteTextColor() {
    return colorFromHex('#FFFFFF');
  }

  static Color getButtonTextColor() {
    return colorFromHex('#100D40');
  }

  static Color getCorrectAnsColor() {
    return colorFromHex('#5D54C1');
  }

  static Color getWrongAnsColor() {
    return colorFromHex('#F05A5A');
  }

  static Color getSubTextColor() {
    return colorFromHex('#100D40').withOpacity(0.8);
  }

  static Color getIconColor() {
    return colorFromHex('#FFFFFF');
  }
}
