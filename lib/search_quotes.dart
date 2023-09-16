import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_share_me/flutter_share_me.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:inspr/pages/share_image.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'common.dart';

List<dynamic> _searchedQuotes = [];
TextEditingController editingController = TextEditingController();

class SearchDialog extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SearchDialog();
  }
}

class _SearchDialog extends State<SearchDialog> {
  @override
  void initState() {
    _searchedQuotes.clear();
    editingController.clear();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void filterSearchResults(String query) {
    if (query.isNotEmpty) {
      List<dynamic> listData = [];
      allQuotes.forEach((element) {
        if (element['author']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            element['quote']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase())) {
          listData.add(<String, dynamic>{
            "id": element['_id'],
            "quote": element['quote'],
            "author": element['author'],
            "is_favorite": (element['favorite'] == 1) ? true : false,
          });
        }
      });
      setState(() {
        _searchedQuotes.clear();
        _searchedQuotes.addAll(listData);
      });
      return;
    }
    setState(() {
      _searchedQuotes.clear();
    });
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
    return Material(
      type: MaterialType.transparency,
      child: SizedBox.expand(
        child: Container(
          color: Theme.of(context).backgroundColor.withOpacity(0.95),
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: Stack(
              children: <Widget>[
                _searchedQuotes.isNotEmpty
                    ? ListView.separated(
                        padding: EdgeInsets.only(top: 100.0, bottom: 20.0),
                        itemCount: _searchedQuotes.length,
                        itemBuilder: (context, index) {
                          return Slidable(
                            // actionPane: SlidableDrawerActionPane(),
                            // actionExtentRatio: 0.25,
                            closeOnScroll: true,
                            child: ListTile(
                              // dense: true,
                              title: Text(
                                '${_searchedQuotes[index]['quote']}',
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
                                      '\u0336 ${_searchedQuotes[index]['author']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color:
                                            Theme.of(context).bottomAppBarColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            endActionPane: ActionPane(
                              motion: DrawerMotion(),
                              children: [
                                SlidableAction(
                                  // label: 'Favorite',
                                  backgroundColor: Theme.of(context)
                                      .highlightColor
                                      .withOpacity(0.8),
                                  foregroundColor:
                                      Theme.of(context).indicatorColor,
                                  icon: _searchedQuotes[index]['is_favorite']
                                      ? MdiIcons.heart
                                      : MdiIcons.heartOutline,
                                  onPressed: (BuildContext context) {
                                    _favoriteQuote(
                                      _searchedQuotes[index]['is_favorite']
                                          ? false
                                          : true,
                                      _searchedQuotes[index]['id'],
                                    );
                                  },
                                ),
                                SlidableAction(
                                  // label: 'Share',
                                  backgroundColor: Theme.of(context)
                                      .highlightColor
                                      .withOpacity(0.6),
                                  foregroundColor:
                                      Theme.of(context).indicatorColor,
                                  icon: MdiIcons.shareVariant,
                                  onPressed: (BuildContext context) async {
                                    var response = await FlutterShareMe()
                                        .shareToSystem(
                                            msg: "\"" +
                                                _searchedQuotes[index]
                                                    ['quote'] +
                                                "\"" +
                                                " \u0020\u0020 \u0336 " +
                                                _searchedQuotes[index]
                                                    ['author']);
                                    if (response != 'success') {
                                      showSnackbar(
                                          context: context,
                                          duration: 2,
                                          message:
                                              "Error sharing quote, try again",
                                          backgroundColor: Colors.deepOrange);
                                    }
                                  },
                                ),
                                SlidableAction(
                                  // label: 'Share',
                                  backgroundColor: Theme.of(context)
                                      .highlightColor
                                      .withOpacity(0.4),
                                  foregroundColor:
                                      Theme.of(context).indicatorColor,
                                  icon: MdiIcons.imageOutline,
                                  onPressed: (BuildContext context) async {
                                    shareImageDialog(_searchedQuotes[index]
                                            ['quote'] +
                                        " \n\n ~ " +
                                        _searchedQuotes[index]['author']);
                                  },
                                ),
                                SlidableAction(
                                  // label: 'Copy',
                                  backgroundColor: Theme.of(context)
                                      .highlightColor
                                      .withOpacity(0.2),
                                  foregroundColor:
                                      Theme.of(context).indicatorColor,
                                  icon: MdiIcons.clipboardTextOutline,
                                  onPressed: (BuildContext context) {
                                    Clipboard.setData(ClipboardData(
                                            text: "\"" +
                                                _searchedQuotes[index]
                                                    ['quote'] +
                                                "\"" +
                                                " \u0020\u0020 \u0336 " +
                                                _searchedQuotes[index]
                                                    ['author']))
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
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              MdiIcons.formatQuoteOpen,
                              color: Theme.of(context)
                                  .bottomAppBarColor
                                  .withOpacity(0.3),
                              size: 60.0,
                            ),
                            Text(
                              "Inspr Quotes",
                              style: TextStyle(
                                color: Theme.of(context).bottomAppBarColor,
                                fontSize: 20.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              "Nothing to display at the moment",
                              style: TextStyle(
                                color: Theme.of(context).bottomAppBarColor,
                                fontSize: 12.0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Theme.of(context).backgroundColor,
                    height: 100,
                    padding: EdgeInsets.fromLTRB(10.0, 40.0, 10.0, 0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: editingController,
                            textAlignVertical: TextAlignVertical.center,
                            enableSuggestions: true,
                            autofocus: true,
                            style: TextStyle(fontSize: 20.0),
                            decoration: InputDecoration(
                              hintText: "Search quotes",
                              hintStyle: TextStyle(
                                color: Theme.of(context).bottomAppBarColor,
                              ),
                              prefixIcon: Icon(Icons.search),
                              border: InputBorder.none,
                            ),
                            keyboardType: TextInputType.text,
                            onChanged: (value) {
                              filterSearchResults(value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 20.0,
                        ),
                        IconButton(
                            icon: Icon(MdiIcons.close),
                            onPressed: () {
                              Navigator.of(context).pop();
                            }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future _favoriteQuote(bool favorite, int id) async {
    var resp = await favoriteQuote(favorite, id);
    setState(() {
      _searchedQuotes = resp;
    });
    filterSearchResults(editingController.value.text);
  }
}
