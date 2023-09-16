import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_share_me/flutter_share_me.dart';
import 'package:inspr/common.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'pages/share_image.dart';
import 'search_quotes.dart';
import 'package:intro_views_flutter/intro_views_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'database_helper.dart';
import 'pages/favorites.dart';
import 'pages/homepage.dart';
import 'pages/settings.dart';
import 'theming.dart';

bool _showLoader = true;
bool _showQuotesLoadError = false;
List<dynamic> _renderedQuotes = [];
Random random = Random();
int initialPage = 0;
PanelController _pc = PanelController();
bool isOnboarding = true;

PageController _controller = PageController(
  initialPage: initialPage,
);

Future<bool> _getAllQuotes() async {
  countFavorites = 0;
  bool state = false;
  await getAllLocalQuotes().then((resp) {
    allQuotes = resp;
    allQuotes.forEach((element) {
      _renderedQuotes.add({
        "id": element['_id'],
        "quote": element['quote'],
        "author": element['author'],
        "is_favorite": (element['favorite'] == 1) ? true : false,
      });
      if (element['favorite'] == 1) {
        countFavorites++;
      }
    });
    //_renderedQuotes.shuffle();
    state = true;
  }).catchError((err) {
    state = false;
  });
  return state;
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (
        X509Certificate cert,
        String host,
        int port,
      ) =>
          true;
  }
}

_httpFix() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
}

void main() {
  _httpFix();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  Future _inspectQuotes() async {
    setState(() {
      _showLoader = true;
      _showQuotesLoadError = false;
    });
    bool response = await initQuotes();
    await _houseKeeping();
    if (response) {
      bool resp = await _getAllQuotes();
      if (resp) {
        setState(() {
          initialPage = random.nextInt(_renderedQuotes.length) + 1;
        });
      }
      setState(() {
        _showLoader = false;
      });
    }
    setState(() {
      !response ? _showQuotesLoadError = true : _showQuotesLoadError = false;
    });
  }

  void onSelectNotification(String? payload) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Payload"),
        content: Text("Payload: $payload"),
      ),
    );
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = info;
    });
  }

  @override
  void initState() {
    super.initState();
    initAppSettings();
    getCurrentAppTheme();
    _inspectQuotes();
    _initPackageInfo();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _houseKeeping() async {
    favEnabled = await dbHelper.queryWhere(DatabaseHelper.settingsTable,
        DatabaseHelper.columnSetting, ['fav_conf_enabled']);
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme =
        await themeChangeProvider.darkThemePreference.getTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) {
      return themeChangeProvider;
    }, child: Consumer<DarkThemeProvider>(
        builder: (BuildContext context, value, Widget? child) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Inspr',
        theme: Styles.themeData(themeChangeProvider.darkTheme, context),
        home: AppShell(),
      );
    }));
  }
}

class AppShell extends StatefulWidget {
  @override
  _AppShellState createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentPage = 0;
  String _pageTitle = '';

  Future _inspectQuotes() async {
    setState(() {
      _showLoader = true;
      _showQuotesLoadError = false;
    });
    bool response = await initQuotes();
    if (response) {
      bool resp = await _getAllQuotes();
      if (resp) {
        setState(() {
          initialPage = random.nextInt(_renderedQuotes.length) + 1;
        });
      }
      setState(() {
        _showLoader = false;
      });
    }
    setState(() {
      !response ? _showQuotesLoadError = true : _showQuotesLoadError = false;
    });
  }

  _renderHomeSwiper() {
    // ignore: deprecated_member_use
    List<Widget> list = <Widget>[];
    _renderedQuotes.forEach((f) {
      list.add(homeSwiper(context: context, currentQuote: f));
    });
    return list;
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
      transitionDuration: Duration(milliseconds: 400),
      barrierLabel: '',
      context: context,
      pageBuilder: (context, animation1, animation2) {
        return SizedBox();
      },
    );
  }

  searchQuoteDialog() {
    return showGeneralDialog(
      // barrierColor: Colors.white.withOpacity(0.5),
      barrierDismissible: false,
      transitionBuilder: (context, a1, a2, widget) {
        final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
          child: Opacity(
            opacity: a1.value,
            child: SearchDialog(),
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 400),
      barrierLabel: '',
      context: context,
      pageBuilder: (context, animation1, animation2) {
        return SizedBox();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _currentPage = 0;
    _pageTitle = "All quotes";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      key: mainScaffoldKey,
      backgroundColor: Theme.of(context).backgroundColor,
      body: !_showLoader
          ? isOnboarding
              ? onboardingPage(context)
              : SlidingUpPanel(
                  controller: _pc,
                  color: Theme.of(context).backgroundColor,
                  parallaxOffset: 0.2,
                  collapsed: Visibility(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(padding: EdgeInsets.only(top: 20.0)),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 4,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: Colors.blueGrey[100],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ]),
                  ),
                  panel: Visibility(
                    visible: true,
                    child: Stack(
                      children: <Widget>[
                        getPage(_currentPage),
                        Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                                padding:
                                    EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                                child: AppBar(
                                  backgroundColor:
                                      Theme.of(context).backgroundColor,
                                  centerTitle: false,
                                  title: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        0.0, 15.0, 0.0, 0.0),
                                    child: Text(
                                      _pageTitle,
                                      style: TextStyle(
                                          color:
                                              Theme.of(context).indicatorColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22.0),
                                    ),
                                  ),
                                  elevation: 0.5,
                                  automaticallyImplyLeading: false,
                                  actions: <Widget>[
                                    ((_currentPage == 0 && isSubscribed) ||
                                            (_currentPage == 0 && isOnTrial))
                                        ? Padding(
                                            padding: EdgeInsets.only(
                                                top: 15.0, right: 12.0),
                                            child: IconButton(
                                              icon: Icon(MdiIcons.magnify,
                                                  color: Theme.of(context)
                                                      .indicatorColor),
                                              iconSize: 22.0,
                                              onPressed: () =>
                                                  searchQuoteDialog(),
                                            ),
                                          )
                                        : SizedBox(),
                                    Padding(
                                      padding: EdgeInsets.only(
                                          top: 15.0, right: 12.0),
                                      child: IconButton(
                                        icon: Icon(MdiIcons.close,
                                            color: Theme.of(context)
                                                .indicatorColor),
                                        iconSize: 22.0,
                                        onPressed: () => _pc.close(),
                                      ),
                                    )
                                  ],
                                  flexibleSpace: Container(
                                    height: 100,
                                  ),
                                ))),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: BottomNavigationBar(
                            backgroundColor:
                                Theme.of(context).bottomAppBarTheme.color,
                            elevation: 0,
                            currentIndex: _currentPage,
                            selectedLabelStyle: TextStyle(
                                color: Theme.of(context).indicatorColor),
                            unselectedLabelStyle: TextStyle(
                                color: Theme.of(context).bottomAppBarColor),
                            selectedItemColor: Theme.of(context).indicatorColor,
                            selectedFontSize: 12.0,
                            items: [
                              BottomNavigationBarItem(
                                icon: Icon(
                                  MdiIcons.cardBulleted,
                                  color: _currentPage == 0
                                      ? Theme.of(context).indicatorColor
                                      : Theme.of(context).bottomAppBarColor,
                                ),
                                label: "All quotes",
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(
                                  MdiIcons.heart,
                                  color: _currentPage == 1
                                      ? Theme.of(context).indicatorColor
                                      : Theme.of(context).bottomAppBarColor,
                                ),
                                label: "Favorites",
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(
                                  MdiIcons.cog,
                                  color: _currentPage == 2
                                      ? Theme.of(context).indicatorColor
                                      : Theme.of(context).bottomAppBarColor,
                                ),
                                label: "Settings",
                              ),
                            ],
                            onTap: (index) {
                              setState(() {
                                _currentPage = index;
                                if (index == 0) {
                                  _pageTitle = "All quotes";
                                } else if (index == 1) {
                                  _pageTitle = "Favorites";
                                } else if (index == 2) {
                                  _pageTitle = "Settings";
                                }
                              });
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                  maxHeight: height,
                  minHeight: 50.0,
                  parallaxEnabled: true,
                  onPanelClosed: () {
                    setState(() {
                      _currentPage = 0;
                      _pageTitle = "All quotes";
                    });
                  },
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 60.0,
                      color: Theme.of(context).dividerColor,
                    ),
                  ],
                  body: Stack(
                    children: <Widget>[
                      Center(
                        child: ScrollConfiguration(
                          behavior: MyBehavior(),
                          child: PageView(
                              controller: _controller,
                              //physics: PageScrollPhysics(),
                              children: _renderHomeSwiper()),
                        ),
                      ),
                      _homeTools(),
                    ],
                  ),
                )
          : Center(
              child: !_showQuotesLoadError
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const <Widget>[
                            CircularProgressIndicator(
                              strokeWidth: 4.0,
                              backgroundColor: Colors
                                  .transparent, //Theme.of(context).bottomAppBarColor,
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding:
                                  EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 2.0),
                              child: Text(
                                'Error!',
                                style: TextStyle(
                                    color: Theme.of(context).bottomAppBarColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800),
                              ),
                            )
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text('Something weird just happened',
                                style: TextStyle(
                                    color: Theme.of(context).bottomAppBarColor,
                                    fontSize: 14))
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding:
                                  EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
                              child: OutlinedButton(
                                child: Row(
                                  children: const <Widget>[Text("Try again")],
                                ),
                                onPressed: !_showLoader
                                    ? null
                                    : () {
                                        _inspectQuotes();
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
                            )
                          ],
                        ),
                      ],
                    ),
            ),
    );
  }

  _homeTools() {
    return Positioned(
        top: 20.0,
        left: 0,
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: EdgeInsets.fromLTRB(15.0, 40.0, 15.0, 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // (!isSubscribed && subscriptionAvailable && !isOnTrial)
              //     ? InkWell(
              //         child: Container(
              //           padding: EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 4.0),
              //           decoration: BoxDecoration(
              //               color: Colors.orange,
              //               borderRadius:
              //                   BorderRadius.all(Radius.circular(20))),
              //           child: Row(
              //             mainAxisAlignment: MainAxisAlignment.center,
              //             crossAxisAlignment: CrossAxisAlignment.center,
              //             children: const <Widget>[
              //               Icon(
              //                 MdiIcons.crown,
              //                 color: Colors.white,
              //                 size: 16.0,
              //               ),
              //               SizedBox(
              //                 width: 4.0,
              //               ),
              //               Text(
              //                 "Inspr Pro",
              //                 style: TextStyle(
              //                   fontWeight: FontWeight.w700,
              //                   color: Colors.white,
              //                 ),
              //               ),
              //             ],
              //           ),
              //         ),
              //         onTap: () {
              //           setState(() {
              //             _currentPage = 2;
              //             _pageTitle = "Settings";
              //           });
              //           getPage(_currentPage);
              //           _pc.open();
              //         },
              //       )
              //     :
              SizedBox(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  IconButton(
                    tooltip: "Randomize Quotes",
                    icon: Icon(
                      MdiIcons.shuffle,
                      color: Theme.of(context).bottomAppBarColor,
                      size: 18.0,
                    ),
                    onPressed: () {
                      setState(() {
                        _renderedQuotes.shuffle();
                        initialPage =
                            random.nextInt(_renderedQuotes.length) + 1;
                        // _controller.jumpToPage(initialPage);
                        _controller.animateToPage(initialPage,
                            duration: Duration(seconds: 1),
                            curve: Curves.decelerate);
                      });
                    },
                  ),
                  // (isSubscribed || isOnTrial) ?
                  IconButton(
                    tooltip: "Search Quotes",
                    icon: Icon(
                      MdiIcons.magnify,
                      color: Theme.of(context).bottomAppBarColor,
                      size: 18.0,
                    ),
                    onPressed: () {
                      searchQuoteDialog();
                    },
                  ),
                  // : SizedBox(),
                  IconButton(
                    tooltip: "More...",
                    icon: Icon(
                      MdiIcons.dotsVertical,
                      color: Theme.of(context).bottomAppBarColor,
                      size: 18.0,
                    ),
                    onPressed: () {
                      _pc.open();
                    },
                  ),
                ],
              )
            ],
          ),
        ));
  }

  getPage(int page) {
    switch (page) {
      case 0:
        return Homepage();
      case 1:
        return Favorites();
      case 2:
        return Settings();
    }
  }

  Widget homeSwiper({required BuildContext context, dynamic currentQuote}) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 0.0, 15.0, 0.0),
                child: Row(
                  children: <Widget>[
                    Icon(
                      MdiIcons.formatQuoteOpen,
                      color: Theme.of(context).bottomAppBarColor,
                      size: 100.0,
                    ),
                  ],
                ),
              ),
              Padding(
                  padding: EdgeInsets.fromLTRB(60.0, 80.0, 15.0, 0.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          currentQuote['quote'],
                          maxLines: 40,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: 20.0,
                            color: Theme.of(context).indicatorColor,
                          ),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
          Padding(
              padding: EdgeInsets.fromLTRB(15.0, 20.0, 15.0, 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    "\u0336 " + currentQuote['author'],
                    style: TextStyle(
                        fontSize: 16.0,
                        color: Theme.of(context).bottomAppBarColor,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              )),
          Padding(
            padding: EdgeInsets.fromLTRB(47.0, 20.0, 15.0, 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                IconButton(
                  icon: Icon(MdiIcons.shareVariant),
                  color: Theme.of(context).bottomAppBarColor,
                  iconSize: 20.0,
                  onPressed: () async {
                    var response = await FlutterShareMe().shareToSystem(
                        msg: "\"" +
                            currentQuote['quote'] +
                            "\"" +
                            " \u0020\u0020 \u0336 " +
                            currentQuote['author']);
                    if (response != 'success') {
                      showSnackbar(
                          context: context,
                          duration: 2,
                          message: "Error sharing quote, try again",
                          backgroundColor: Colors.deepOrange);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(MdiIcons.imageOutline),
                  color: Theme.of(context).bottomAppBarColor,
                  iconSize: 20.0,
                  onPressed: () async {
                    shareImageDialog(currentQuote['quote'] +
                        " \n\n ~ " +
                        currentQuote['author']);
                  },
                ),
                IconButton(
                  icon: Icon(MdiIcons.clipboardTextOutline),
                  color: Theme.of(context).bottomAppBarColor,
                  iconSize: 20.0,
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: "\"" +
                            currentQuote['quote'] +
                            "\"" +
                            " \u0020\u0020 \u0336 " +
                            currentQuote['author'],
                      ),
                    ).then((data) {
                      showSnackbar(
                        context: context,
                        duration: 2,
                        message: "Quote coppied to clipboard",
                      );
                    });
                  },
                ),
                // Padding(padding: EdgeInsets.only(right: 10.0),),
                IconButton(
                  icon: Icon(currentQuote['is_favorite']
                      ? MdiIcons.heart
                      : MdiIcons.heartOutline),
                  color: Theme.of(context).bottomAppBarColor,
                  iconSize: 20.0,
                  onPressed: () {
                    // if (isSubscribed || isOnTrial) {
                    _favoriteQuote(currentQuote['is_favorite'] ? false : true,
                        currentQuote['id']);
                    if (currentQuote['is_favorite']) {
                      setState(() {
                        countFavorites--;
                      });
                    } else {
                      setState(() {
                        countFavorites++;
                      });
                    }
                    // } else {
                    //   if (countFavorites >= favoritesLimit) {
                    //     showSnackbar(
                    //         context: context,
                    //         duration: 3,
                    //         message:
                    //             "Subscribe to Pro to favorite more quotes.",
                    //         backgroundColor: Colors.deepOrange);
                    //   } else {
                    //     _favoriteQuote(
                    //         currentQuote['is_favorite'] ? false : true,
                    //         currentQuote['id']);
                    //     if (currentQuote['is_favorite']) {
                    //       setState(() {
                    //         countFavorites--;
                    //       });
                    //     } else {
                    //       setState(() {
                    //         countFavorites++;
                    //       });
                    //     }
                    //   }
                    // }
                  },
                ),
                // Visibility(
                //   visible: isSubscribed,
                //   child: IconButton(
                //     icon: Icon(MdiIcons.pinOutline),
                //     color: Theme.of(context).bottomAppBarColor,
                //     iconSize: 20.0,
                //     onPressed: (){},
                //   ),
                // ),
              ],
            ),
          ),
        ]);
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

  Widget onboardingPage(BuildContext context) {
    final pages = [
      PageViewModel(
        pageColor: Color(0xF6F6F7FF),
        bubbleBackgroundColor: Theme.of(context).bottomAppBarColor,
        title: Container(),
        body: Column(
          children: <Widget>[
            Text(
              "Inspr gets you inspired",
              style: TextStyle(
                  color: Theme.of(context).bottomAppBarColor,
                  fontWeight: FontWeight.w700),
            ),
            Expanded(
              child: Text(
                "With 1.7K+ inspirational & motivational quotes, you're sure to stay inspired.",
                style: TextStyle(
                    color: Theme.of(context).bottomAppBarColor, fontSize: 16.0),
              ),
            )
          ],
        ),
        mainImage: Image.asset(
          'assets/inspire.png',
          width: 285.0,
          alignment: Alignment.bottomCenter,
        ),
        textStyle: TextStyle(color: Colors.black),
      ),
      PageViewModel(
        pageColor: Color(0xF6F6F7FF),
        bubbleBackgroundColor: Theme.of(context).bottomAppBarColor,
        title: Container(),
        body: Column(
          children: <Widget>[
            Text(
              "Quotes randomized",
              style: TextStyle(
                  color: Theme.of(context).bottomAppBarColor,
                  fontWeight: FontWeight.w700),
            ),
            Expanded(
              child: Text(
                "Quotes shown on the homescreen are randomized whenever you launch the app. Swipe right or left to show more quotes",
                style: TextStyle(
                    color: Theme.of(context).bottomAppBarColor, fontSize: 16.0),
              ),
            )
          ],
        ),
        mainImage: Image.asset(
          'assets/screen2.png',
          width: 285.0,
          alignment: Alignment.bottomCenter,
        ),
        textStyle: TextStyle(color: Colors.black),
      ),
      PageViewModel(
        pageColor: Color(0xF6F6F7FF),
        bubbleBackgroundColor: Theme.of(context).bottomAppBarColor,
        title: Container(),
        body: Column(
          children: <Widget>[
            Text(
              "Smart lists for quotes",
              style: TextStyle(
                  color: Theme.of(context).bottomAppBarColor,
                  fontWeight: FontWeight.w700),
            ),
            Expanded(
              child: Text(
                "Swipe up from the bottom to display more tabs: All quotes, Favorites and Settings. From the lists, actions have been simplified to swipe activities.",
                style: TextStyle(
                    color: Theme.of(context).bottomAppBarColor, fontSize: 16.0),
              ),
            )
          ],
        ),
        mainImage: Image.asset(
          'assets/screen3.png',
          width: 285.0,
          alignment: Alignment.bottomCenter,
        ),
        textStyle: TextStyle(color: Colors.black),
      ),
    ];

    return SafeArea(
      child: Stack(
        children: <Widget>[
          IntroViewsFlutter(
            pages,
            onTapDoneButton: () async {
              setState(() {
                isOnboarding = false;
              });
              await userOnboarded();
            },
            showSkipButton: true,
            skipText: Text(
              "SKIP",
              style: TextStyle(
                color: Theme.of(context).bottomAppBarColor,
              ),
            ),
            doneText: Text(
              "DONE",
              style: TextStyle(
                color: Theme.of(context).bottomAppBarColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            pageButtonsColor: Colors.deepOrange,
            pageButtonTextStyles: TextStyle(
              // color: Colors.deepOrange,
              fontSize: 16.0,
              fontFamily: "Regular",
            ),
          ),
          // Positioned(
          //   top: 20.0,
          //   left: MediaQuery.of(context).size.width/2 - 36,
          //   child: Image.asset('assets/onboarding-logo.png', height: 80,)
          // )
        ],
      ),
    );
  }
}
