import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../common.dart';

List<dynamic> _renderedQuotes = [];

class Favorites extends StatefulWidget {
  @override
  _FavoritesState createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  bool _fav = false;
  @override
  void initState() {
    _renderedQuotes.clear();
    allQuotes.forEach((element) {
      if (element['favorite'] == 1) {
        _renderedQuotes.add({
          "id": element['_id'],
          "quote": element['quote'],
          "author": element['author'],
          "is_favorite": (element['favorite'] == 1) ? true : false,
        });
      }
    });
    //_renderedQuotes.shuffle();
    _fav = (favEnabled[0]['value'] == 'true') ? true : false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _renderedQuotes.isNotEmpty
        ? ListView.separated(
            padding: EdgeInsets.only(top: 110.0, bottom: 80.0),
            itemCount: _renderedQuotes.length,
            itemBuilder: (context, index) {
              final item = _renderedQuotes[index];
              return Dismissible(
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _favoriteQuote(
                      _renderedQuotes[index]['is_favorite'] ? false : true,
                      _renderedQuotes[index]['id']);
                  setState(() {
                    _renderedQuotes.removeAt(index);
                    countFavorites--;
                  });
                  // showSnackbar(context: context, duration: 2, message: "Quote removed from favorites");
                },
                key: Key(item.toString()),
                background: Container(
                  // color: Colors.deepOrangeAccent,
                  color: Theme.of(context).highlightColor.withOpacity(0.8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const <Widget>[
                      Icon(
                        MdiIcons.trashCan,
                        color: Colors.deepOrange,
                        size: 20.0,
                      ),
                      Padding(padding: EdgeInsets.only(right: 8)),
                      Padding(
                          child: Text(
                            "Remove from favorites",
                            style: TextStyle(color: Colors.deepOrange),
                          ),
                          padding: EdgeInsets.only(top: 3, right: 16)),
                    ],
                  ),
                ),
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
                              // ignore: deprecated_member_use
                              color: Theme.of(context).bottomAppBarColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                confirmDismiss: _fav
                    ? (DismissDirection direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Remove favorite?"),
                              content: Text(
                                '"${_renderedQuotes[index]['quote']}", by ${_renderedQuotes[index]['author']}',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .indicatorColor
                                      .withOpacity(0.9),
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: Theme.of(context).indicatorColor,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                ),
                                // ignore: deprecated_member_use
                                TextButton(
                                  child: Text(
                                    "Remove",
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    : null,
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
                  MdiIcons.emoticonSad,
                  color: Theme.of(context).bottomAppBarColor,
                  size: 40.0,
                ),
                Text(
                  "There's nothing here",
                  style: TextStyle(
                      color: Theme.of(context).bottomAppBarColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 20.0),
                ),
                Text(
                  "You don't have any favorites",
                  style: TextStyle(
                      color: Theme.of(context).bottomAppBarColor,
                      //fontWeight: FontWeight.w900,
                      fontSize: 12.0),
                )
              ],
            ),
          );
  }

  Future _favoriteQuote(bool favorite, int id) async {
    await favoriteQuote(favorite, id);
    showSnackbar(
      context: context,
      duration: 2,
      message: "Quote removed from favorites",
    );
  }
}
