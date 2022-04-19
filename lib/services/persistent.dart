import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sih/localization.dart';

String getTranslated(BuildContext context, String key) {
  return DemoLocalization.of(context).getTranslatedValue(key);
}

String getNumberTranslated(BuildContext context, String key) {
  String convertedNumber = ' ';

  for (int i = 0; i <= key.length - 1 && key[i] != '.'; i++) {
    print('step $i :' + key[i]);
    convertedNumber = convertedNumber +
        DemoLocalization.of(context).getTranslatedValue(key[i]);
  }
  print(convertedNumber);
  return convertedNumber;
}

const String ENGLISH = 'en';
const String HINDI = 'hi';

const String LANGUAGE_CODE = 'languageCode';

Future<Locale> setLocale(String languageCode) async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  await _prefs.setString(LANGUAGE_CODE, languageCode);

  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  Locale _temp;
  switch (languageCode) {
    case ENGLISH:
      print(languageCode);
      _temp = Locale(languageCode, 'US');

      break;
    case HINDI:
      print(languageCode);
      print('change in hindi ??');

      _temp = Locale(languageCode, 'IN');

      break;
    default:
      print(languageCode);
      _temp = Locale(ENGLISH, 'US');
  }
  return _temp;
}

Future<Locale> getLocale() async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  String languageCode = _prefs.getString(LANGUAGE_CODE) ?? ENGLISH;

  return _locale(languageCode);
}
