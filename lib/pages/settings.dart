import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:launch_review/launch_review.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../common.dart';
import '../database_helper.dart';
import '../subscription.dart';
import '../theming.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
GoogleSignInAccount? _currentUser;

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool favConfVal = false;
  bool pushVal = false;
  bool soundVal = false;
  bool vibrationVal = false;
  String theme = "Light";
  String pushTime = "08:00";

  @override
  void initState() {
    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
      });
    });
    googleSignIn.signInSilently();
    super.initState();
    getCurrentPushNotificationsSettings();
  }

  @override
  void dispose() {
    //subscription.cancel();
    super.dispose();
  }

  void getCurrentPushNotificationsSettings() {
    bool _fav = (favEnabled[0]['value'] == 'true') ? true : false;
    bool _val = (pushEnabled[0]['value'] == 'true') ? true : false;
    bool _soundval = (soundEnabled[0]['value'] == 'true') ? true : false;
    bool _vibrationval =
        (vibrationEnabled[0]['value'] == 'true') ? true : false;
    String _time = notificationTime[0]['value'];
    setState(() {
      favConfVal = _fav;
      pushVal = _val;
      soundVal = _soundval;
      vibrationVal = _vibrationval;
      pushTime = _time;
    });
  }

  void updateSetting(Map<String, dynamic> row) async {
    await dbHelper.update(row, DatabaseHelper.settingsTable);
    _handleDailyNotification();
  }

  Future _scheduleNotification(bool vibrate, bool playSound,
      String scheduledTime, String title, String notification) async {
    var hour = int.parse(scheduledTime.split(":")[0]);
    var minute = int.parse(scheduledTime.split(":")[1]);
    var time = Time(hour, minute, 0);
    var vibrationPattern = Int64List(4);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 1000;
    vibrationPattern[2] = 5000;
    vibrationPattern[3] = 2000;
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'channel id', 'channel name',
        channelDescription: 'channel description',
        importance: Importance.max,
        priority: Priority.high,
        playSound: playSound,
        enableVibration: vibrate,
        vibrationPattern: vibrationPattern);
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    // ignore: deprecated_member_use
    await flutterLocalNotificationsPlugin.showDailyAtTime(
      0,
      title,
      notification,
      time,
      platformChannelSpecifics,
      payload: playSound ? 'No_Sound' : 'Default_Sound',
    );
  }

  _handleDailyNotification() async {
    favEnabled = await dbHelper.queryWhere(DatabaseHelper.settingsTable,
        DatabaseHelper.columnSetting, ['fav_conf_enabled']);
    notificationTime = await dbHelper.queryWhere(DatabaseHelper.settingsTable,
        DatabaseHelper.columnSetting, ['notification_time']);
    soundEnabled = await dbHelper.queryWhere(DatabaseHelper.settingsTable,
        DatabaseHelper.columnSetting, ['sound_enabled']);
    vibrationEnabled = await dbHelper.queryWhere(DatabaseHelper.settingsTable,
        DatabaseHelper.columnSetting, ['vibration_enabled']);
    bool _val = (pushEnabled[0]['value'] == 'true') ? true : false;
    bool _soundval = (soundEnabled[0]['value'] == 'true') ? true : false;
    bool _vibrationval =
        (vibrationEnabled[0]['value'] == 'true') ? true : false;
    String _time = notificationTime[0]['value'];
    await flutterLocalNotificationsPlugin.cancelAll();
    if (_val) {
      await _scheduleNotification(_vibrationval, _soundval, _time,
          "Get inspired", "A few quotes today will keep you inspired.");
    }
  }

  String _strTime(int val) {
    return (val < 10) ? "0$val" : val.toString();
  }

  String _amPm(String val) {
    var hour = int.parse(val.split(":")[0]);
    return (hour < 12) ? "AM" : "PM";
  }

  String _displayTime(String val) {
    String _time;
    var hour = int.parse(val.split(":")[0]);
    var minute = val.split(":")[1];
    var a = _amPm(val);
    if (hour > 12) {
      hour = hour - 12;
    }
    if (hour == 0) {
      hour = 12;
    }
    _time = "$hour:$minute $a";
    return _time;
  }

  _rate() {
    LaunchReview.launch(androidAppId: "co.ke.martin.inspr", writeReview: true);
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    setState(() {
      theme = themeChange.darkTheme ? "Dark" : "Light";
    });

    Future _selectTime() async {
      TimeOfDay _startTime = TimeOfDay(
          hour: int.parse(pushTime.split(":")[0]),
          minute: int.parse(pushTime.split(":")[1]));
      TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: _startTime,
      );
      if (picked != null) {
        String _time = _strTime(picked.hour) + ":" + _strTime(picked.minute);
        //print(_time);
        updateSetting({
          '_id': notificationTime[0]['_id'],
          'setting': 'notification_time',
          'value': _time,
          'modified_on': DateTime.now().millisecondsSinceEpoch
        });
        setState(() {
          pushTime = _time;
        });
        showSnackbar(
            context: context,
            duration: 2,
            message: "Daily reminder time changed");
        return picked;
      }
      return null;
    }

    proDialog() {
      return showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return GoProDialog(
              signInStatus: (val) {
                setState(() {
                  signedIn = val;
                });
              },
              subscriptionStatus: (sval) {
                setState(() {
                  isSubscribed = sval;
                });
              },
            );
          });
    }

    ImageProvider<Object> _getAvatar(String? avatar) {
      if (avatar == "" || avatar == null) {
        return AssetImage('assets/no-user.png');
      }
      return CachedNetworkImageProvider(currentUser['avatar']);
    }

    _displayUserProfile() {
      return (isSubscribed && !isOnTrial)
          ? InkWell(
              child: Padding(
                padding: EdgeInsets.only(left: 16.0, bottom: 16.0),
                child: Row(
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(right: 10.0, top: 8.0),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: _getAvatar(currentUser['avatar']),
                                fit: BoxFit.cover,
                              ),
                              //border: Border.all(color: Colors.grey[300], width: 3.0,),
                            ),
                          ),
                        ),
                        Positioned(
                          child: Icon(
                            MdiIcons.crown,
                            color: Colors.orange,
                            size: 24.0,
                          ),
                          right: 0,
                          top: 0,
                        ),
                      ],
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            currentUser['display_name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20.0,
                            ),
                          ),
                          Text(
                            currentUser['email'],
                            style: TextStyle(
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                proDialog();
              },
            )
          : SizedBox();
    }

    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0.0, 100.0, 0.0, 80.0),
        child: Column(
          children: <Widget>[
            // const SizedBox(height: 10.0),
            // (!isSubscribed && subscriptionAvailable && !isOnTrial)
            //     ? InkWell(
            //         onTap: () {
            //           proDialog();
            //         },
            //         child: Container(
            //             color: Colors.orange,
            //             child: Padding(
            //               padding: EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 15.0),
            //               child: Row(
            //                 mainAxisAlignment: MainAxisAlignment.start,
            //                 children: const <Widget>[
            //                   Padding(
            //                     padding: EdgeInsets.only(right: 5.0),
            //                     child: Center(
            //                       child: Icon(
            //                         MdiIcons.crown,
            //                         color: Colors.white,
            //                         size: 26.0,
            //                       ),
            //                     ),
            //                   ),
            //                   Column(
            //                     crossAxisAlignment: CrossAxisAlignment.start,
            //                     children: <Widget>[
            //                       Text(
            //                         "Inspr Pro",
            //                         style: TextStyle(
            //                             color: Colors.white,
            //                             fontWeight: FontWeight.w900,
            //                             fontSize: 14.0),
            //                       ),
            //                       Text(
            //                         "Get the most out of Inspr",
            //                         style: TextStyle(
            //                             color: Colors.white,
            //                             fontWeight: FontWeight.w500,
            //                             fontSize: 10.0),
            //                       )
            //                     ],
            //                   ),
            //                 ],
            //               ),
            //             )),
            //       )
            //     : SizedBox(),
            // _displayUserProfile(),
            PopupMenuButton(
              child: ListTile(
                title: Text(
                  "App theme",
                  style: TextStyle(
                      color: Theme.of(context).indicatorColor,
                      fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  theme,
                  style: TextStyle(color: Theme.of(context).bottomAppBarColor),
                ),
                trailing: Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 0.0, 16.0, 0.0),
                  child: Icon(
                    Icons.keyboard_arrow_right,
                    color: Theme.of(context).bottomAppBarColor,
                  ),
                ),
              ),
              onSelected: (String value) {
                setState(() {
                  theme = value;
                  theme == "Dark"
                      ? themeChange.darkTheme = true
                      : themeChange.darkTheme = false;
                });
                showSnackbar(
                    context: context,
                    duration: 2,
                    message: "$theme theme successfully applied");
              },
              offset: Offset.fromDirection(1.0),
              itemBuilder: (context) => [
                PopupMenuItem(
                    value: "Light",
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Icon(MdiIcons.lightbulbOnOutline,
                            color: Theme.of(context).indicatorColor),
                        Padding(padding: EdgeInsets.only(left: 10.0)),
                        Text("Light",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).indicatorColor)),
                      ],
                    )),
                PopupMenuItem(
                    value: "Dark",
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Icon(MdiIcons.lightbulbOn,
                            color: Theme.of(context).indicatorColor),
                        Padding(padding: EdgeInsets.only(left: 10.0)),
                        Text("Dark",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).indicatorColor)),
                      ],
                    )),
                // PopupMenuItem(
                //   value: "System",
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.start,
                //     children: <Widget>[
                //       Icon(MdiIcons.lightbulbOutline, color: Theme.of(context).indicatorColor),
                //       Padding(
                //         padding: EdgeInsets.only(left: 10.0)
                //       ),
                //       Text("System", style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).indicatorColor)),
                //     ],
                //   )
                // ),
              ],
            ),
            SwitchListTile(
              activeColor: Colors.orange,
              title: Text(
                "Remove from favorites confirm",
                style: TextStyle(
                  color: Theme.of(context).indicatorColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                favConfVal ? "Enabled" : "Disabled",
                style: TextStyle(color: Theme.of(context).bottomAppBarColor),
              ),
              value: favConfVal ? true : false,
              onChanged: (bool value) {
                updateSetting({
                  '_id': favEnabled[0]['_id'],
                  'setting': 'fav_conf_enabled',
                  'value': value.toString(),
                  'modified_on': DateTime.now().millisecondsSinceEpoch
                });
                setState(() {
                  favConfVal = value;
                });
                showSnackbar(
                  context: context,
                  duration: 2,
                  message: "Remove from favorites confirm " +
                      (favConfVal ? "enabled" : "disabled"),
                );
              },
            ),
            SwitchListTile(
              activeColor: Colors.orange,
              title: Text(
                isSubscribed
                    ? "Daily quote notification"
                    : "Daily reminder notification",
                style: TextStyle(
                    color: Theme.of(context).indicatorColor,
                    fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                pushVal ? "Enabled" : "Disabled",
                style: TextStyle(color: Theme.of(context).bottomAppBarColor),
              ),
              value: pushVal ? true : false,
              onChanged: (bool value) {
                updateSetting({
                  '_id': pushEnabled[0]['_id'],
                  'setting': 'push_enabled',
                  'value': value.toString(),
                  'modified_on': DateTime.now().millisecondsSinceEpoch
                });
                setState(() {
                  pushVal = value;
                });
                showSnackbar(
                    context: context,
                    duration: 2,
                    message:
                        "Daily reminder " + (pushVal ? "enabled" : "disabled"));
              },
            ),
            SwitchListTile(
              activeColor: Colors.orange,
              title: Text(
                "Notification sound",
                style: TextStyle(
                    color: Theme.of(context).indicatorColor,
                    fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                soundVal ? "Enabled" : "Disabled",
                style: TextStyle(color: Theme.of(context).bottomAppBarColor),
              ),
              value: soundVal ? true : false,
              onChanged: !pushVal
                  ? null
                  : (bool value) {
                      updateSetting({
                        '_id': soundEnabled[0]['_id'],
                        'setting': 'sound_enabled',
                        'value': value.toString(),
                        'modified_on': DateTime.now().millisecondsSinceEpoch
                      });
                      setState(() {
                        soundVal = value;
                      });
                      showSnackbar(
                          context: context,
                          duration: 2,
                          message: "Notification sound " +
                              (soundVal ? "enabled" : "disabled"));
                    },
            ),
            SwitchListTile(
              activeColor: Colors.orange,
              title: Text(
                "Vibration",
                style: TextStyle(
                    color: Theme.of(context).indicatorColor,
                    fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                vibrationVal ? "Enabled" : "Disabled",
                style: TextStyle(color: Theme.of(context).bottomAppBarColor),
              ),
              value: vibrationVal ? true : false,
              onChanged: !pushVal
                  ? null
                  : (bool value) {
                      updateSetting({
                        '_id': vibrationEnabled[0]['_id'],
                        'setting': 'vibration_enabled',
                        'value': value.toString(),
                        'modified_on': DateTime.now().millisecondsSinceEpoch
                      });
                      setState(() {
                        vibrationVal = value;
                      });
                      showSnackbar(
                        context: context,
                        duration: 2,
                        message: "Vibration " +
                            (vibrationVal ? "enabled" : "disabled"),
                      );
                    },
            ),
            ListTile(
              title: Text(
                "Notification Time",
                style: TextStyle(
                    color: pushVal ? Theme.of(context).indicatorColor : null,
                    fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                _displayTime(pushTime),
                style: TextStyle(
                  color: pushVal ? Theme.of(context).bottomAppBarColor : null,
                ),
              ),
              trailing: Padding(
                padding: EdgeInsets.fromLTRB(0.0, 0.0, 16.0, 0.0),
                child: Icon(
                  Icons.keyboard_arrow_right,
                  color: pushVal ? Theme.of(context).bottomAppBarColor : null,
                ),
              ),
              onTap: () {
                _selectTime();
              },
              enabled: pushVal,
            ),
            ListTile(
              title: Text(
                "Rate ${packageInfo.appName}",
                style: TextStyle(color: Theme.of(context).indicatorColor),
              ),
              subtitle: Text(
                'v${packageInfo.version}+${packageInfo.buildNumber}',
                style: TextStyle(
                  color: Theme.of(context).bottomAppBarColor,
                ),
              ),
              trailing: Padding(
                padding: EdgeInsets.fromLTRB(0.0, 0.0, 16.0, 0.0),
                child: Icon(
                  Icons.keyboard_arrow_right,
                  color: Theme.of(context).bottomAppBarColor,
                ),
              ),
              onTap: () {
                _rate();
              },
            ),
          ],
        ));
  }
}

class GoProDialog extends StatefulWidget {
  GoProDialog({
    required this.subscriptionStatus,
    required this.signInStatus,
  });

  final ValueChanged<bool> subscriptionStatus;
  final ValueChanged<bool> signInStatus;

  @override
  State<StatefulWidget> createState() {
    return _GoProDialog();
  }
}

class _GoProDialog extends State<GoProDialog> {
  bool _showSpinner = false;

  @override
  void initState() {
    //listen to subscriptions
    subscription = inAppPurchase.purchaseStream.listen(
        (data) => setState(() {
              print('Subscription >>=================>>>>>> ');
              print(data);
              _showSpinner = true;
              purchases.addAll(data);
              var vdata = {};
              vdata = verifyPurchase();
              print("vData >>>>>>>>>>>>> $isSubscribed");
              print(vdata);
              if (vdata.isNotEmpty) {
                //add to db here
                addSubscriptionData(
                  email: _currentUser?.email,
                  expirytime: vdata['expirytime'],
                  orderid: vdata['orderid'],
                  productid: vdata['productid'],
                  purchasetime: vdata['purchasetime'],
                  status: vdata['status'],
                ).then((resp) {
                  print('Server response >>');
                  print(resp);
                  if (resp['response_code'] == 4) {
                    // isSubscribed = false;
                    _showSpinner = false;
                    showSnackbar(
                      context: context,
                      duration: 5,
                      message: "Error encountered, please try again",
                      backgroundColor: Colors.deepOrange,
                      textColor: Colors.white,
                    );
                    Navigator.of(context).pop();
                  } else if (resp['response_code'] == 200) {
                    updateSubscription(vdata);
                    // isSubscribed = true;
                    _showSpinner = false;
                    widget.subscriptionStatus(true);
                    showSnackbar(
                      context: context,
                      duration: 7,
                      message: "Your Pro subscription is active",
                    );
                    Navigator.of(context).pop();
                  }
                });
              } else {
                _showSpinner = false;
                widget.subscriptionStatus(false);
                showSnackbar(
                    context: context,
                    duration: 7,
                    message:
                        "Payment hasn't been confirmed yet, please try again",
                    backgroundColor: Colors.deepOrange,
                    textColor: Colors.white);
                Navigator.of(context).pop();
              }
            }), onError: (error) {
      setState(() {
        // isSubscribed = false;
        _showSpinner = false;
      });
      showSnackbar(
        context: context,
        duration: 5,
        message: "Error encountered, please try again",
        backgroundColor: Colors.deepOrange,
        textColor: Colors.white,
      );
      Navigator.of(context).pop();
      print("Buy subscription error >> $error");
    });
    super.initState();
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  void updateSubscription(dynamic _subscrObj) async {
    var userSubscription = await dbHelper.queryWhere(
        DatabaseHelper.settingsTable,
        DatabaseHelper.columnSetting,
        ['subscription']);
    if (userSubscription.isNotEmpty) {
      await dbHelper.update({
        '_id': userSubscription[0]['_id'],
        'setting': 'subscription',
        'value': (_subscrObj != '') ? json.encode(_subscrObj) : '',
        'modified_on': DateTime.now().millisecondsSinceEpoch
      }, DatabaseHelper.settingsTable);
    } else {
      Map<String, dynamic> saveSubscr = {
        DatabaseHelper.columnSetting: 'subscription',
        DatabaseHelper.columnSettingValue:
            (_subscrObj != '') ? json.encode(_subscrObj) : '',
        DatabaseHelper.columnCreatedOn: DateTime.now().millisecondsSinceEpoch,
        DatabaseHelper.columnModifiedOn: DateTime.now().millisecondsSinceEpoch
      };
      await dbHelper.insert(saveSubscr, DatabaseHelper.settingsTable);
    }
  }

  Future<String> saveCurrentUser(dynamic _userObj) async {
    var userData = await dbHelper.queryWhere(DatabaseHelper.settingsTable,
        DatabaseHelper.columnSetting, ['current_user']);
    String response = 'fail';
    if (userData.isNotEmpty) {
      await dbHelper.update({
        '_id': userData[0]['_id'],
        'setting': 'current_user',
        'value': json.encode(_userObj),
        'modified_on': DateTime.now().millisecondsSinceEpoch
      }, DatabaseHelper.settingsTable);
    } else {
      Map<String, dynamic> saveUser = {
        DatabaseHelper.columnSetting: 'current_user',
        DatabaseHelper.columnSettingValue: json.encode(_userObj),
        DatabaseHelper.columnCreatedOn: DateTime.now().millisecondsSinceEpoch,
        DatabaseHelper.columnModifiedOn: DateTime.now().millisecondsSinceEpoch
      };
      await dbHelper.insert(saveUser, DatabaseHelper.settingsTable);
    }
    //reset local current user data
    currentUserRow = await dbHelper.queryWhere(DatabaseHelper.settingsTable,
        DatabaseHelper.columnSetting, ['current_user']);
    if (currentUserRow.isNotEmpty) {
      if (currentUserRow[0]['value'] != '') {
        setState(() {
          currentUser = json.decode(currentUserRow[0]['value']);
        });
      }
      response = 'success';
    }
    return response;
  }

  void _googleLogin() {
    setState(() {
      _showSpinner = true;
    });
    _handleSignIn();
  }

  Future<void> _handleSignIn() async {
    try {
      await googleSignIn.signIn().then((result) {
        _currentUser = result!;
        var _userObj = {
          'display_name': _currentUser?.displayName,
          'email': _currentUser?.email,
          'avatar': _currentUser?.photoUrl,
          'id': _currentUser?.id
        };
        addUser(
          avatar: (_currentUser?.photoUrl) as String,
          displayName: (_currentUser?.displayName) as String,
          email: _currentUser?.email,
          idToken: _currentUser?.id,
        ).then((resp) {
          if (resp['status'] == 4) {
            //record already exists in online db...
            saveCurrentUser(_userObj).then((value) {
              if (value == 'success') {
                getUserSubscriptionData(
                  email: _currentUser?.email,
                ).then((userSubscrData) {
                  if (userSubscrData['status'] == 1) {
                    // If exists in remote DB, save it to local db
                    var vdata = {
                      'orderid': userSubscrData['data']['order_id'],
                      'purchasetime': userSubscrData['data']['purchase_time'],
                      'expirytime': userSubscrData['data']['expiry_time'],
                      'productid': userSubscrData['data']['product_id'],
                      'status': userSubscrData['data']['status'],
                    };
                    updateSubscription(vdata);
                    setState(() {
                      widget.subscriptionStatus(true);
                      signedIn =
                          (currentUserRow[0]['value'] == '') ? false : true;
                      widget.signInStatus(true);
                      isSubscribed = true;
                      _showSpinner = false;
                    });
                    showSnackbar(
                      context: context,
                      duration: 7,
                      message: "Your Pro subscription is active",
                    );
                    Navigator.of(context).pop();
                  } else {
                    // Doesn't exist in DB
                    buyProduct(subscriptionData);
                    setState(() {
                      signedIn =
                          (currentUserRow[0]['value'] == '') ? false : true;
                      widget.signInStatus(true);
                      _showSpinner = false;
                    });
                    Navigator.of(context).pop();
                  }
                });
              } else {
                showSnackbar(
                  context: context,
                  duration: 5,
                  message: customMessages('error_login_general_msg'),
                );
                Navigator.of(context).pop();
              }
            });
          } else if (resp['status'] == 1) {
            //first time user, save object to db
            saveCurrentUser(_userObj).then((value) {
              if (value == 'success') {
                //continue to pro
                buyProduct(subscriptionData);
                setState(() {
                  signedIn = (currentUserRow[0]['value'] == '') ? false : true;
                  widget.signInStatus(true);
                  // _showSpinner = false;
                });
              } else {
                showSnackbar(
                  context: context,
                  duration: 5,
                  message: customMessages('error_login_general_msg'),
                );
                Navigator.of(context).pop();
              }
            });
          } else {
            showSnackbar(
              context: context,
              duration: 5,
              message: customMessages('error_login_general_msg'),
            );
            Navigator.of(context).pop();
          }
        });
      });
    } catch (error) {
      setState(() {
        _showSpinner = false;
        // signedIn = false;
      });
      showSnackbar(
        context: context,
        duration: 5,
        message: customMessages('error_something_weird_happened_msg'),
      );
      Navigator.of(context).pop();
    }
  }

  getProFeatures() {
    List<Widget> features = [];
    proFeatures.forEach((f) => features.add(
          Text(
            "\u2713  $f",
            style: TextStyle(
              // color: Theme.of(context).bottomAppBarColor,
              fontWeight: FontWeight.w400,
              fontSize: 15.0,
            ),
          ),
        ));
    return features;
  }

  void localDBLogout(Map<String, dynamic> row) async {
    await dbHelper.update(row, DatabaseHelper.settingsTable);
  }

  void _handleSignOut() async {
    await googleSignIn.signOut().then((result) {
      localDBLogout({
        '_id': currentUserRow[0]['_id'],
        'setting': 'current_user',
        'value': '',
        'modified_on': DateTime.now().millisecondsSinceEpoch
      });
      updateSubscription('');
      setState(() {
        currentUser = {};
        signedIn = false;
        isSubscribed = false;
        widget.signInStatus(false);
      });
      showSnackbar(
          context: context, duration: 2, message: "Logged out successfully.");
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    });
  }

  void _logoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Text("Logout"),
          content: Text(
              "Are you sure you want to log out? You won't get the most out of Inspr."),
          actions: <Widget>[
            // ignore: deprecated_member_use
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // ignore: deprecated_member_use
            TextButton(
              child: Text(
                "Logout",
                style: TextStyle(color: Colors.orange),
              ),
              onPressed: () {
                _handleSignOut();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SizedBox.expand(
          child: Container(
        color: Theme.of(context).backgroundColor.withOpacity(0.8),
        child: !signedIn || !isSubscribed
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/onboarding-logo.png',
                    height: 80,
                  ),
                  Text(
                    "Get the most out of Inspr",
                    style: TextStyle(
                        color: Theme.of(context).bottomAppBarColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.0),
                  ),
                  Padding(padding: EdgeInsets.all(10.0)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: getProFeatures(),
                  ),
                  Padding(padding: EdgeInsets.all(10.0)),
                  Text(
                    subscriptionData.price,
                    style: TextStyle(
                        color: Colors
                            .orange, //Theme.of(context).bottomAppBarColor,
                        fontWeight: FontWeight.w300,
                        fontSize: 28.0),
                  ),
                  Text(
                    subscriptionData.description,
                    //"\u2605 \u2605 \u2605 \u2605 \u2605",
                    style: TextStyle(
                        color: Theme.of(context).bottomAppBarColor,
                        fontWeight: FontWeight.w300,
                        fontSize: 12.0),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20.0),
                    child: _showSpinner
                        ? CircularProgressIndicator(
                            strokeWidth: 4.0,
                            backgroundColor: Colors
                                .transparent, //Theme.of(context).bottomAppBarColor,
                          )
                        : SizedBox(
                            width: 120.0,
                            child: OutlinedButton(
                              child: Text(
                                "Subscribe",
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16.0),
                              ),
                              onPressed: () {
                                _googleLogin();
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 12),
                                side: BorderSide(
                                  width: 3.0,
                                  color: Theme.of(context).bottomAppBarColor,
                                  style: BorderStyle.solid,
                                ),
                                textStyle: TextStyle(
                                  color: Theme.of(context).bottomAppBarColor,
                                ),
                              ),
                            ),
                          ),
                  )
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    MdiIcons.crown,
                    color: Colors.orange,
                    size: 42.0,
                  ),
                  Padding(padding: EdgeInsets.all(1.0)),
                  Text(
                    "Inspr Pro",
                    style: TextStyle(
                        color: Theme.of(context).bottomAppBarColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 20.0),
                  ),
                  Text(
                    "Your subscription is active",
                    style: TextStyle(
                        color: Theme.of(context).bottomAppBarColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 12.0),
                  ),
                  Padding(padding: EdgeInsets.all(4.0)),
                  OutlinedButton(
                    child: Text(
                      "Logout",
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16.0),
                    ),
                    onPressed: () {
                      _logoutDialog();
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      side: BorderSide(
                        width: 3.0,
                        color: Theme.of(context).bottomAppBarColor,
                        style: BorderStyle.solid,
                      ),
                      textStyle: TextStyle(
                        color: Theme.of(context).bottomAppBarColor,
                      ),
                    ),
                  )
                ],
              ),
      )),
    );
  }
}
