import 'package:flutter/material.dart';
import 'package:launch_review/launch_review.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../common.dart';
import '../database_helper.dart';
import '../theming.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool favConfVal = false;
  bool pushVal = false;
  String theme = "Light";

  @override
  void initState() {
    super.initState();
    getCurrentPushNotificationsSettings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void getCurrentPushNotificationsSettings() {
    bool _fav = (favEnabled[0]['value'] == 'true') ? true : false;
    bool _val = (pushEnabled[0]['value'] == 'true') ? true : false;
    setState(() {
      favConfVal = _fav;
      pushVal = _val;
    });
  }

  void updateSetting(Map<String, dynamic> row) async {
    await dbHelper.update(row, DatabaseHelper.settingsTable);
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

    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0.0, 100.0, 0.0, 80.0),
        child: Column(
          children: <Widget>[
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
            // SwitchListTile(
            //   activeColor: Colors.orange,
            //   title: Text(
            //     "Quotes push notifications",
            //     style: TextStyle(
            //         color: Theme.of(context).indicatorColor,
            //         fontWeight: FontWeight.w500),
            //   ),
            //   subtitle: Text(
            //     pushVal ? "Enabled" : "Disabled",
            //     style: TextStyle(color: Theme.of(context).bottomAppBarColor),
            //   ),
            //   value: pushVal ? true : false,
            //   onChanged: (bool value) {
            //     updateSetting({
            //       '_id': pushEnabled[0]['_id'],
            //       'setting': 'push_enabled',
            //       'value': value.toString(),
            //       'modified_on': DateTime.now().millisecondsSinceEpoch
            //     });
            //     setState(() {
            //       pushVal = value;
            //     });
            //     showSnackbar(
            //         context: context,
            //         duration: 2,
            //         message: "Quotes push notifications " +
            //             (pushVal ? "enabled" : "disabled"));
            //   },
            // ),
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
