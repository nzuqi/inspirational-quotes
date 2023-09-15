import 'package:flutter/material.dart';
import 'database_helper.dart';

class DarkThemePreference {
  final dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _theme = [
    {'value': 'dark'}
  ];

  setDarkTheme(bool value) async {
    try {
      await dbHelper.update({
        '_id': _theme[0]['_id'],
        'setting': 'theme',
        'value': value ? 'dark' : 'light',
        'modified_on': DateTime.now().millisecondsSinceEpoch
      }, DatabaseHelper.settingsTable);
    } catch (e) {
      //
    }
  }

  Future<bool> getTheme() async {
    _theme = await dbHelper.queryWhere(
        DatabaseHelper.settingsTable, DatabaseHelper.columnSetting, ['theme']);
    bool resp = true;
    if (_theme.isNotEmpty) {
      resp = (_theme[0]['value'] == 'light') ? false : true;
    }
    return resp;
  }
}

class DarkThemeProvider with ChangeNotifier {
  DarkThemePreference darkThemePreference = DarkThemePreference();
  bool _darkTheme = false;

  bool get darkTheme => _darkTheme;

  set darkTheme(bool value) {
    _darkTheme = value;
    darkThemePreference.setDarkTheme(value);
    notifyListeners();
  }
}

class Styles {
  static ThemeData themeData(bool isDarkTheme, BuildContext context) {
    return ThemeData(
      primarySwatch: Colors.orange,
      // ignore: deprecated_member_use
      backgroundColor: isDarkTheme ? Colors.blueGrey[900] : Colors.white,
      primaryColor: isDarkTheme ? Colors.black : Colors.white,
      indicatorColor:
          isDarkTheme ? Colors.blueGrey[100] : Colors.blueGrey[600], //done
      // buttonColor: isDarkTheme ? Color(0xff3B3B3B) : Color(0xffF1F5FB),
      hintColor: isDarkTheme ? Color(0xff280C0B) : Color(0xffEECED3),
      highlightColor:
          isDarkTheme ? Colors.blueGrey[800] : Colors.grey[300], //done
      hoverColor: isDarkTheme ? Color(0xff3A3A3B) : Color(0xff4285F4),
      focusColor: isDarkTheme ? Color(0xff0B2512) : Color(0xffA8DAB5),
      disabledColor: Colors.grey,
      // textSelectionColor: isDarkTheme ? Colors.white : Colors.black,
      cardColor: isDarkTheme ? Colors.blueGrey : Colors.white, //done
      canvasColor: isDarkTheme ? Colors.black : Colors.grey[50],
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      buttonTheme: Theme.of(context).buttonTheme.copyWith(
            colorScheme: isDarkTheme ? ColorScheme.dark() : ColorScheme.light(),
          ),
      bottomAppBarTheme: BottomAppBarTheme(
        //done
        color: isDarkTheme
            ? Colors.blueGrey[900]
            : Colors
                .white, //isDarkTheme ? Colors.blueGrey[800] : Colors.grey[200]
      ),
      // ignore: deprecated_member_use
      bottomAppBarColor:
          isDarkTheme ? Colors.blueGrey[400] : Colors.blueGrey[300], //done
      // ignore: deprecated_member_use
      toggleableActiveColor:
          isDarkTheme ? Colors.orange[700] : Colors.orange, //done
      // accentColor: isDarkTheme ? Colors.orange[700] : Colors.orange, //done
      dividerColor: isDarkTheme ? Colors.grey[900] : Colors.grey[300],
    );
  }
}
