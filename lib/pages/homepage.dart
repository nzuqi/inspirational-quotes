import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_share_me/flutter_share_me.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:inspr/pages/share_image.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../common.dart';

List<dynamic> _renderedQuotes = [];

class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  void initState() {
    _renderedQuotes.clear();
    allQuotes.forEach((element) {
      _renderedQuotes.add({
        "id": element['_id'],
        "quote": element['quote'],
        "author": element['author'],
        "is_favorite": (element['favorite'] == 1) ? true : false,
      });
    });
    //_renderedQuotes.shuffle();
    super.initState();
  }

  shareImageDialog(String quote) {
    return showGeneralDialog(
      // barrierColor: Colors.white.withOpacity(0.5),
      barrierDismissible: false,
      transitionBuilder: (context, a1, a2, widget) {
        final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
          child: Opacity(
            opacity: a1.value,
            child: ShareImageDialog(quote),
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 300),
      barrierLabel: '',
      context: context,
      pageBuilder: (context, animation1, animation2) {
        return SizedBox();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.only(top: 110.0, bottom: 80.0),
      itemCount: _renderedQuotes.length,
      itemBuilder: (context, index) {
        return Slidable(
          // actionPane: SlidableDrawerActionPane(),
          // actionExtentRatio: 0.25,
          closeOnScroll: true,
          // ignore: avoid_unnecessary_containers
          child: Container(
            child: ListTile(
              // dense: true,
              title: Text(
                '${_renderedQuotes[index]['quote']}',
                style: TextStyle(
                  color: Theme.of(context).indicatorColor,
                ),
              ),
              subtitle: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      '\u0336 ${_renderedQuotes[index]['author']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).bottomAppBarColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // startActionPane: ActionPane(
          //   motion: DrawerMotion(),
          //   children: [],
          // ),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            children: [
              SlidableAction(
                // label: 'Favorite',
                backgroundColor:
                    Theme.of(context).highlightColor.withOpacity(0.8),
                foregroundColor: Theme.of(context).indicatorColor,
                icon: _renderedQuotes[index]['is_favorite']
                    ? MdiIcons.heart
                    : MdiIcons.heartOutline,
                onPressed: (BuildContext context) {
                  _favoriteQuote(
                    _renderedQuotes[index]['is_favorite'] ? false : true,
                    _renderedQuotes[index]['id'],
                  );
                },
              ),
              SlidableAction(
                // label: 'Share',
                backgroundColor:
                    Theme.of(context).highlightColor.withOpacity(0.6),
                foregroundColor: Theme.of(context).indicatorColor,
                icon: MdiIcons.shareVariant,
                onPressed: (BuildContext context) async {
                  var response = await FlutterShareMe().shareToSystem(
                      msg: "\"" +
                          _renderedQuotes[index]['quote'] +
                          "\"" +
                          " \u0020\u0020 \u0336 " +
                          _renderedQuotes[index]['author']);
                  if (response != 'success') {
                    showSnackbar(
                        context: context,
                        duration: 2,
                        message: "Error sharing quote, try again",
                        backgroundColor: Colors.deepOrange);
                  }
                },
              ),
              SlidableAction(
                // label: 'Share',
                backgroundColor:
                    Theme.of(context).highlightColor.withOpacity(0.6),
                foregroundColor: Theme.of(context).indicatorColor,
                icon: MdiIcons.imageOutline,
                onPressed: (BuildContext context) async {
                  shareImageDialog(_renderedQuotes[index]['quote'] +
                      " \n\n ~ " +
                      _renderedQuotes[index]['author']);
                },
              ),
              SlidableAction(
                // label: 'Copy',
                backgroundColor:
                    Theme.of(context).highlightColor.withOpacity(0.4),
                foregroundColor: Theme.of(context).indicatorColor,
                icon: MdiIcons.clipboardTextOutline,
                onPressed: (BuildContext context) {
                  Clipboard.setData(ClipboardData(
                          text: "\"" +
                              _renderedQuotes[index]['quote'] +
                              "\"" +
                              " \u0020\u0020 \u0336 " +
                              _renderedQuotes[index]['author']))
                      .then((data) {
                    showSnackbar(
                      context: context,
                      duration: 2,
                      message: "Quote coppied to clipboard",
                    );
                  });
                },
              ),
            ],
          ),
        );
      },
      separatorBuilder: (context, index) {
        return Divider(
          color: Theme.of(context).highlightColor,
        );
      },
    );
  }

  Future _favoriteQuote(bool favorite, int id) async {
    var resp = await favoriteQuote(favorite, id);
    setState(() {
      _renderedQuotes = resp;
    });
    var msg = favorite ? "added to" : "removed from";
    showSnackbar(
      context: context,
      duration: 2,
      message: "Quote $msg favorites",
    );
  }
}
