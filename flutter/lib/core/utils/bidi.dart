import 'package:flutter/widgets.dart';

final RegExp _rtlCharacters = RegExp(r'[\u0590-\u08FF]');
final RegExp _latinCharacters = RegExp(r'[A-Za-z]');

TextDirection directionForText(String text) {
  final rtl = _rtlCharacters.allMatches(text).length;
  final latin = _latinCharacters.allMatches(text).length;
  if (rtl == 0) return TextDirection.ltr;
  if (latin == 0) return TextDirection.rtl;
  return rtl >= latin * 0.45 ? TextDirection.rtl : TextDirection.ltr;
}
