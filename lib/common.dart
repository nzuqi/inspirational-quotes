import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:inspr/env.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'database_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

final GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();

dynamic pushEnabled = {};
dynamic favEnabled = {};
dynamic userOnboarding = {};

int trialDays = 0;

final random = Random();
PackageInfo packageInfo = PackageInfo(
  appName: 'Unknown',
  packageName: 'Unknown',
  version: 'Unknown',
  buildNumber: 'Unknown',
  buildSignature: 'Unknown',
);

Map<String, String> headers = {
  "Accept": "application/json",
  "content-type": "application/json",
  "Authorization": "JnZvSW784mzDCOzuFEXV"
};

final dbHelper = DatabaseHelper.instance;

List<dynamic> allQuotes = [];

customMessages(String key) {
  var messages = {
    "error_fetching_data_msg":
        "Oops! Something happened while fetching your data.", //"Oops! Something happened while fetching your data. We'll get it right next time.",
    "error_something_weird_happened_msg":
        "Oh no! Something weird just happened, please try again.",
    "error_login_general_msg":
        "Oops! We encountered an error while signing you in. Please try again.",
    "saved_successfully_msg":
        "Saved successfully! We'll remember this next time.",
    "off_days_saved_successfully_msg":
        "Off days saved successfully! We'll notify you.",
    "off_days_saving_error_msg":
        "Oops! Cannot save your off days. Check your internet connection and try again.",
    "saving_error_msg":
        "Oops! Cannot save your settings. Check your internet connection and try again.",
    "internet_error_msg":
        "Oops! Cannot connect to the internet. Check your connection and try again.",
    "off_day_added_msg": "Selected off day added to list.",
    "alert_applied_msg": "Alert configured successfully.",
    "archive_msg": "Off day archived successfully.",
    "delete_msg": "Off day deleted successfully.",
    "delete_holiday_msg": "Holiday deleted successfully.",
    "unarchive_msg": "Archived off day restored successfully.",
    "verification_email_sent":
        "A verification cde has been sent to your email successfully.",
    "verification_code_err":
        "An error occurred while verifying your email. Please try again.",
  };
  return messages[key];
}

void initAppSettings() async {
  // int count = await dbHelper.queryRowCount(DatabaseHelper.settingsTable);
  // if (count == 0) {
  Map<String, dynamic> defaultFavConf = {
    DatabaseHelper.columnSetting: 'fav_conf_enabled',
    DatabaseHelper.columnSettingValue: 'true',
    DatabaseHelper.columnCreatedOn: DateTime.now().millisecondsSinceEpoch,
    DatabaseHelper.columnModifiedOn: DateTime.now().millisecondsSinceEpoch
  };
  Map<String, dynamic> defaultTheme = {
    DatabaseHelper.columnSetting: 'theme',
    DatabaseHelper.columnSettingValue: 'dark',
    DatabaseHelper.columnCreatedOn: DateTime.now().millisecondsSinceEpoch,
    DatabaseHelper.columnModifiedOn: DateTime.now().millisecondsSinceEpoch
  };
  Map<String, dynamic> defaultPushEnabled = {
    DatabaseHelper.columnSetting: 'push_enabled',
    DatabaseHelper.columnSettingValue: 'true',
    DatabaseHelper.columnCreatedOn: DateTime.now().millisecondsSinceEpoch,
    DatabaseHelper.columnModifiedOn: DateTime.now().millisecondsSinceEpoch
  };
  Map<String, dynamic> userOnboarding = {
    DatabaseHelper.columnSetting: 'user_onboarding',
    DatabaseHelper.columnSettingValue: 'false',
    DatabaseHelper.columnCreatedOn: DateTime.now().millisecondsSinceEpoch,
    DatabaseHelper.columnModifiedOn: DateTime.now().millisecondsSinceEpoch
  };

  var favConfEnabledCheck = await dbHelper.queryWhere(
      DatabaseHelper.settingsTable,
      DatabaseHelper.columnSetting,
      ['fav_conf_enabled']);
  var themeCheck = await dbHelper.queryWhere(
      DatabaseHelper.settingsTable, DatabaseHelper.columnSetting, ['theme']);
  var pushEnabledCheck = await dbHelper.queryWhere(DatabaseHelper.settingsTable,
      DatabaseHelper.columnSetting, ['push_enabled']);
  var userOnboardingCheck = await dbHelper.queryWhere(
      DatabaseHelper.settingsTable,
      DatabaseHelper.columnSetting,
      ['user_onboarding']);

  if (favConfEnabledCheck.isEmpty) {
    await dbHelper.insert(defaultFavConf, DatabaseHelper.settingsTable);
  }
  if (themeCheck.isEmpty) {
    await dbHelper.insert(defaultTheme, DatabaseHelper.settingsTable);
  }
  if (pushEnabledCheck.isEmpty) {
    await dbHelper.insert(defaultPushEnabled, DatabaseHelper.settingsTable);
  }
  if (userOnboardingCheck.isEmpty) {
    await dbHelper.insert(userOnboarding, DatabaseHelper.settingsTable);
  }
  // }
}

void getAppSettings() async {
  final allRows = await dbHelper.queryAllRows(DatabaseHelper.settingsTable);
  allRows.forEach((row) => print(row));
}

Uri endpoint(String path) {
  return kDebugMode
      ? Uri.http(Environment.debugUrl, path)
      : Uri.https(Environment.prodUrl, path);
}

Future getAllRemoteQuotes() async {
  return await http.get(endpoint('/api/quotes'), headers: headers).then((resp) {
    return json.decode(resp.body);
  });
}

Future getAllLocalQuotes() async {
  return await dbHelper.queryAllRows(DatabaseHelper.quotesTable);
}

showSnackbar(
    {context,
    required int duration,
    required String message,
    Color backgroundColor = Colors.blueGrey,
    Color textColor = Colors.white}) async {
  ScaffoldMessenger.of(context).removeCurrentSnackBar(
    reason: SnackBarClosedReason.remove,
  );
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: textColor),
      ),
      duration: Duration(seconds: duration),
      backgroundColor: backgroundColor,
    ),
  );
}

showSnackbarWithCallback(
    {context,
    required int duration,
    required String message,
    required String actionLabel,
    required Function() action,
    required Color actionLabelColor,
    Color backgroundColor = Colors.orange,
    Color textColor = Colors.white}) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: textColor),
      ),
      duration: Duration(seconds: duration),
      action: SnackBarAction(
        label: actionLabel,
        onPressed: action,
        textColor: actionLabelColor,
      ),
      backgroundColor: backgroundColor,
    ),
  );
}

Future<bool> initQuotes() async {
  int? count = await dbHelper.queryRowCount(DatabaseHelper.quotesTable);
  if (count == 0) {
    return await _overwriteLocalDB();
  } else {
    return true;
  }
}

Future _overwriteLocalDB() async {
  List<dynamic> _allQuotes = [];
  return await getAllRemoteQuotes().then((resp) {
    if (resp['data'].isEmpty) {
      return false;
    } else {
      resp['data'].forEach((row) {
        _allQuotes.add({
          'remote_id': row['id'],
          'quote': row['quote'],
          'author': row['author'],
          'created_on': DateTime.now().millisecondsSinceEpoch,
          'modified_on': DateTime.now().millisecondsSinceEpoch
        });
      });
      dbHelper.batchInsert(_allQuotes, DatabaseHelper.quotesTable);
      return true;
    }
  }).catchError((error) {
    return false;
  });
}

class MyBehavior extends ScrollBehavior {
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

Future favoriteQuote(bool favorite, int id) async {
  Map<String, dynamic> row = {
    '_id': id,
    'favorite': favorite ? 1 : 0,
  };
  await dbHelper.update(row, DatabaseHelper.quotesTable);
  List<dynamic> _quotes = [];
  await getAllLocalQuotes().then((resp) {
    allQuotes = resp;
    allQuotes.forEach((element) {
      _quotes.add({
        "id": element['_id'],
        "quote": element['quote'],
        "author": element['author'],
        "is_favorite": (element['favorite'] == 1) ? true : false,
      });
    });
  });
  return _quotes;
}

Future userOnboarded() async {
  if (userOnboarding.isNotEmpty) {
    await dbHelper.update({
      '_id': userOnboarding[0]['_id'],
      'setting': 'user_onboarding',
      'value': 'true',
      'modified_on': DateTime.now().millisecondsSinceEpoch
    }, DatabaseHelper.settingsTable);
  } else {
    Map<String, dynamic> userOnboarding = {
      DatabaseHelper.columnSetting: 'user_onboarding',
      DatabaseHelper.columnSettingValue: 'true',
      DatabaseHelper.columnCreatedOn: DateTime.now().millisecondsSinceEpoch,
      DatabaseHelper.columnModifiedOn: DateTime.now().millisecondsSinceEpoch
    };
    await dbHelper.insert(userOnboarding, DatabaseHelper.settingsTable);
  }
}

generateRandomNumber({required int min, required int max}) {
  /**
 * Generates a positive random integer uniformly distributed on the range
 * from [min], inclusive, to [max], exclusive.
 */
  return min + random.nextInt(max - min);
}
