import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../common.dart';
import '../zoomable_image.dart';
import 'package:share_plus/share_plus.dart';

class ShareImageDialog extends StatefulWidget {
  final String currentQuote;
  const ShareImageDialog(this.currentQuote);

  @override
  State<StatefulWidget> createState() {
    return _ShareImageDialog();
  }
}

class _ShareImageDialog extends State<ShareImageDialog>
    with SingleTickerProviderStateMixin {
  final double _initialSliderHeight = 80;
  double _sliderHeight = 80;
  TabController? tabController;
  TextStyle? selectedTextstyle;
  String imageSource = "internet";
  GlobalKey previewContainer = GlobalKey();
  double editBoxSize = 200.0;
  double x = 10.0;
  double y = 200.0;
  String textToShare = "";
  final Color _appBackgroundColor = Color(0xff880E4F);
  final textController = TextEditingController();
  String? previewImage;
  double fontSize = 30.0;
  String selectedFont = "Caveat";
  TextAlign textAlign = TextAlign.end;
  bool showProgressOnGenerate = false;
  String filterApplied = "default";
  Widget? zoom;
  Widget? oldzoom;
  Color quoteColor = Colors.white;
  Color currentPickerColor = Colors.white;
  List layouts = [
    {"text": "Caveat"},
    {"text": "LatoLight"},
    {"text": "LatoBold"},
    {"text": "IndieFlower"},
    {"text": "Montserrat"},
    {"text": "Satisfy"},
    {"text": "SpecialElite"},
  ];
  List fontsizes = [
    {"size": 20.0},
    {"size": 30.0},
    {"size": 40.0}
  ];
  List<double> filterMatrix = [
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  List backgrounds = [
    "https://images.unsplash.com/photo-1516571748831-5d81767b788d",
    "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee",
    "https://images.unsplash.com/photo-1506598417715-e3c191368ac0",
    "https://images.unsplash.com/photo-1500817487388-039e623edc21",
    "https://images.unsplash.com/photo-1498590880827-3f79fdcd7fbe",
    "https://images.unsplash.com/photo-1513682322455-ea8b2d81d418",
    "https://images.unsplash.com/photo-1508781378177-4a8e7e4ef6c1",
    "https://images.unsplash.com/photo-1543625247-45477d03e12f",
    "https://images.unsplash.com/photo-1517279509087-dd1bb691b553",
    "https://images.unsplash.com/photo-1542729109-a29eb764b161",
    "https://images.unsplash.com/photo-1542910523-cefe90e6423f",
    "https://images.unsplash.com/photo-1561216674-d2d75399a6da",
    "https://images.unsplash.com/photo-1523703591032-c582f1eedf32",
    "https://images.unsplash.com/photo-1518247213313-0a400b4936e4",
    "https://images.unsplash.com/photo-1558174935-ed21e82aab29",
    "https://images.unsplash.com/photo-1504575212242-686eeb50560d",
    "https://images.unsplash.com/photo-1526631880652-71a048b9b492",
    "https://images.unsplash.com/photo-1473081556163-2a17de81fc97",
    "https://images.unsplash.com/photo-1530090382228-7195e08d7a75",
    "https://images.unsplash.com/photo-1465966756657-fc05dc0a5bf0",
    "https://images.unsplash.com/photo-1499982722725-f65678ee86bb",
    "https://images.unsplash.com/photo-1505635552518-3448ff116af3",
    "https://images.unsplash.com/photo-1518156677180-95a2893f3e9f",
    "https://images.unsplash.com/photo-1529950285869-b8f6cf5a7fd0",
    "https://images.unsplash.com/photo-1519074069444-1ba4fff66d16",
    "https://images.unsplash.com/photo-1682687218608-5e2522b04673",
    "https://images.unsplash.com/photo-1549577748-efbbdefd7bb0",
    "https://images.unsplash.com/photo-1556648011-e01aca870a81",
    "https://images.unsplash.com/photo-1534364432722-54585249d766",
    "https://images.unsplash.com/photo-1429734956993-8a9b0555e122",
  ];

  String backgroundImage =
      "https://images.unsplash.com/photo-1500817487388-039e623edc21";
  final double _defaultImageWidth = 1200;

  @override
  void initState() {
    tabController = TabController(length: 3, vsync: this);
    selectedTextstyle =
        TextStyle(color: quoteColor, fontSize: 30, fontFamily: "Caveat");
    localPath();
    textToShare = widget.currentQuote;
    textController.text = textToShare;
    _loadAImagesFromDownload();
    backgroundImage =
        backgrounds[generateRandomNumber(min: 1, max: backgrounds.length)];
    currentPickerColor = quoteColor;
    super.initState();
  }

  // @override
  // void dispose() {
  //   super.dispose();
  // }

  // Future<String> _loadAImagesFromAsset() async {
  //   try {
  //     var images = await rootBundle.loadString('assets/images.json');
  //     var responseJSON = json.decode(images);
  //     return images;
  //   } catch (err) {
  //     return null;
  //   }
  // }

  Future<List<String>?> _loadAImagesFromDownload() async {
    try {
      final directory = await getExternalStorageDirectory();
      var images =
          await rootBundle.loadString(directory!.path + '/images.json');
      var responseJSON = json.decode(images);
      // ignore: deprecated_member_use
      List<String> img = [];
      for (var _i = 0; _i < responseJSON["images"].length; _i++) {
        img.add(responseJSON["images"][_i]);
      }
      setState(() {
        backgrounds = img;
        backgroundImage = img[0];
      });
      return img;
    } catch (err) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery.of(context).size.width;
    double _height = MediaQuery.of(context).size.height;
    double _maxHeightBottomSheet = _height - _initialSliderHeight - 20;
    double _middleHeightBottomSheet = _height / 2 - _initialSliderHeight;
    var _layouts = layouts.map<Widget>((book) => _fontView(book)).toList();
    var _fontSizes = fontsizes.map<Widget>((font) {
      // ignore: avoid_unnecessary_containers
      return Container(
        child: GestureDetector(
          onTap: () {
            setState(
              () {
                fontSize = font["size"];
                selectedTextstyle = TextStyle(
                  fontSize: font["size"],
                  fontFamily: selectedFont,
                  color: quoteColor,
                );
              },
            );
          },
          child: Container(
            color: Colors.blueGrey[800],
            alignment: Alignment.center,
            child: Text(
              "A",
              style: TextStyle(
                fontSize: font["size"],
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }).toList();
    var _textAlignments = ["left", "center", "right"].map<Widget>((align) {
      // ignore: avoid_unnecessary_containers
      return Container(
          child: GestureDetector(
        onTap: () {
          setState(() {
            textAlign = align == "left"
                ? TextAlign.left
                : align == "center"
                    ? TextAlign.center
                    : TextAlign.right;
          });
        },
        child: Container(
            color: Colors.blueGrey[600],
            child: Icon(
              align == "left"
                  ? Icons.format_align_left
                  : align == "center"
                      ? Icons.format_align_center
                      : Icons.format_align_right,
              color: Colors.white,
              size: 20,
            )),
      ));
    }).toList();
    var menusOnFont = _fontSizes..addAll(_textAlignments);
    editBoxSize = _width - 10;
    var _backgrounds = [
      _pickfromGallery(),
      ...backgrounds.map<Widget>((image) => _makeBackground(image)).toList()
    ];
    DecorationImage? _backgroundImageFromSource;

    if (imageSource == "internet") {
      _backgroundImageFromSource = DecorationImage(
          colorFilter: ColorFilter.matrix(filterMatrix),
          image:
              NetworkImage(backgroundImage + "?w=" + _width.toInt().toString()),
          fit: BoxFit.cover);
    } else if (imageSource == "gallery") {
      _backgroundImageFromSource = DecorationImage(
          colorFilter: ColorFilter.matrix(filterMatrix),
          image: FileImage(File(backgroundImage)),
          fit: BoxFit.cover);
    }

    return Material(
      type: MaterialType.transparency,
      child: SizedBox.expand(
        child: Container(
          color: Theme.of(context).backgroundColor.withOpacity(0.8),
          child: Stack(
            children: <Widget>[
              // mainBackground(context, _width, _height, _backgroundImageFromSource,
              // backgroundImage, imageSource, filterMatrix),
              buildBackground(
                  context,
                  _width,
                  _height,
                  _backgroundImageFromSource,
                  backgroundImage,
                  imageSource,
                  filterMatrix),
              // _saveScreenShotButton(context),
              _closeButton(context),
              _screenShotButton(context),
              // previewDownloadedImage(),
              _appBottomSheetMenus(
                  context,
                  _width,
                  _height,
                  _middleHeightBottomSheet,
                  _maxHeightBottomSheet,
                  _layouts,
                  _backgrounds,
                  _fontSizes,
                  menusOnFont),
              showProgressOnGenerate
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Column()
            ],
          ),
        ),
      ),
    );
  }

  Border _imagePreviewBorder = Border.all(color: Colors.black, width: 2.0);

  Widget previewDownloadedImage() {
    return previewImage != null
        ? Positioned(
            bottom: 100,
            left: 5,
            child: GestureDetector(
              onTapDown: (tap) {
                setState(() {
                  _imagePreviewBorder =
                      Border.all(color: Colors.white70, width: 2.0);
                });
                share();
              },
              onTapUp: (tap) {
                setState(() {
                  _imagePreviewBorder =
                      Border.all(color: Colors.black, width: 2.0);
                });
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: _imagePreviewBorder,
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 10,
                      offset: Offset(0.3, 0.6),
                    )
                  ],
                  color: _appBackgroundColor,
                  shape: BoxShape.rectangle,
                  image: DecorationImage(
                    image: FileImage(File(previewImage!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          )
        : Container();
  }

  Widget buildBackground(BuildContext context, _width, _height,
      _backgroundImageFromSource, backgroundImage, imageSource, filterMatrix) {
    return RepaintBoundary(
      key: previewContainer,
      // ignore: sized_box_for_whitespace
      child: Container(
        width: _width,
        height: _height,
        child: Stack(
          children: <Widget>[
            imageSource == "internet"
                ? CachedNetworkImage(
                    placeholder: (context, url) =>
                        Center(child: CircularProgressIndicator()),
                    imageUrl: backgroundImage +
                        "?w=" +
                        _defaultImageWidth.toInt().toString(),
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                          image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.matrix(filterMatrix),
                      )),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage("assets/default.jpg"),
                              colorFilter: ColorFilter.matrix(filterMatrix),
                              fit: BoxFit.cover)),
                    ),
                  )
                : Container(
                    width: _width,
                    height: _height,
                    color: Colors.black87,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.matrix(filterMatrix),
                      child: zoom ?? Container(),
                    ),
                  ),
            lyricsText(_width, _height, context),
            // Positioned(
            //   bottom: 4,
            //   right: 4,
            //   child: Container(
            //     decoration: BoxDecoration(
            //       boxShadow: [
            //         BoxShadow(
            //           color: Colors.black,
            //           blurRadius: 100,
            //           offset: Offset(0.3, 0.6)
            //         )
            //       ],
            //       image: DecorationImage(
            //         image: AssetImage("assets/watermark.png"),
            //         colorFilter: ColorFilter.matrix(filterMatrix),
            //         fit: BoxFit.cover
            //       )
            //     ),
            //     width: 90,
            //     height: 24,
            //     child: Column()
            //   ),
            // )
          ],
        ),
      ),
    );
  }

  Widget mainBackground(BuildContext context, _width, _height,
      _backgroundImageFromSource, backgroundImage, imageSource, filterMatrix) {
    return RepaintBoundary(
      key: previewContainer,
      // ignore: sized_box_for_whitespace
      child: Container(
        width: _width,
        height: _height,
        child: Stack(
          children: <Widget>[
            imageSource == "internet"
                ? CachedNetworkImage(
                    placeholder: (context, url) =>
                        Center(child: CircularProgressIndicator()),
                    imageUrl: backgroundImage +
                        "?w=" +
                        _defaultImageWidth.toInt().toString(),
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                          image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.matrix(filterMatrix),
                      )),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage("assets/default.jpg"),
                              colorFilter: ColorFilter.matrix(filterMatrix),
                              fit: BoxFit.cover)),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: FileImage(File(backgroundImage)),
                            colorFilter: ColorFilter.matrix(filterMatrix),
                            fit: BoxFit.cover)),
                  ),
            lyricsText(_width, _height, context),
            // Positioned(
            //   bottom: 4,
            //   right: 4,
            //   child: Container(
            //       decoration: BoxDecoration(
            //           boxShadow: [
            //             BoxShadow(
            //                 color: Colors.black,
            //                 blurRadius: 100,
            //                 offset: Offset(0.3, 0.6))
            //           ],
            //           image: DecorationImage(
            //               image: AssetImage("assets/watermark.png"),
            //               colorFilter: ColorFilter.matrix(filterMatrix),
            //               fit: BoxFit.cover)),
            //       width: 90,
            //       height: 24,
            //       child: Column()),
            // )
          ],
        ),
      ),
    );
  }

  Widget _closeButton(BuildContext context) {
    return Positioned(
      top: 50,
      left: 30,
      child: InkWell(
        child: Container(
          decoration:
              BoxDecoration(shape: BoxShape.rectangle, boxShadow: const [
            BoxShadow(
              spreadRadius: 50.0,
              offset: Offset(0, 0),
              color: Color.fromARGB(200, 0, 0, 0),
              blurRadius: 100.0,
            ),
          ]),
          child: Icon(
            MdiIcons.close,
            color: Colors.white,
            size: 24.0,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _screenShotButton(BuildContext context) {
    return Positioned(
      top: 50,
      right: 30,
      child: InkWell(
        child: Container(
          decoration:
              BoxDecoration(shape: BoxShape.rectangle, boxShadow: const [
            BoxShadow(
              spreadRadius: 50.0,
              offset: Offset(0, 0),
              color: Color.fromARGB(200, 0, 0, 0),
              blurRadius: 100.0,
            ),
          ]),
          child: Icon(
            MdiIcons.shareVariant,
            color: Colors.white,
            size: 24.0,
          ),
        ),
        onTap: () {
          if (!showProgressOnGenerate) {
            FocusScope.of(context).requestFocus(FocusNode());
            takeScreenShot(context);
          }
        },
      ),
    );
  }

  Widget _appBottomSheetMenus(
      BuildContext context,
      _width,
      _height,
      _middleHeightBottomSheet,
      _maxHeightBottomSheet,
      _layouts,
      _backgrounds,
      _fontSizes,
      menusOnFont) {
    return Positioned(
      bottom: 0,
      child: Container(
        width: _width,
        decoration: BoxDecoration(shape: BoxShape.rectangle, boxShadow: const [
          BoxShadow(
              spreadRadius: 100.0,
              offset: Offset(0, 60),
              color: Color.fromARGB(150, 0, 0, 0),
              blurRadius: 100.0)
        ]),
        child: Column(
          children: <Widget>[
            _bottomSheetScrollButton(context, _width, _height,
                _middleHeightBottomSheet, _maxHeightBottomSheet),
            ClipRRect(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25.0),
                  topRight: Radius.circular(25.0)),
              child: AnimatedContainer(
                duration: Duration(seconds: 1),
                curve: Curves.fastLinearToSlowEaseIn,
                width: _width,
                height: _sliderHeight,
                color: Colors.transparent,
                // ignore: avoid_unnecessary_containers
                child: Container(
                  child: Column(
                    children: <Widget>[
                      TabBar(
                          controller: tabController,
                          indicatorColor: Theme.of(context).bottomAppBarColor,
                          labelColor: Theme.of(context).bottomAppBarColor,
                          indicatorWeight: 3.0,
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.filter_hdr),
                            ),
                            Tab(
                              icon: Icon(Icons.text_fields),
                            ),
                            Tab(
                              icon: Icon(Icons.photo_filter),
                            ),
                          ]),
                      Expanded(
                          child: SizedBox(
                              child: TabBarView(
                                  controller: tabController,
                                  children: [
                            CustomScrollView(
                              primary: false,
                              slivers: <Widget>[
                                SliverPadding(
                                  padding: const EdgeInsets.all(20),
                                  sliver: SliverGrid.count(
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      crossAxisCount: 3,
                                      children: _backgrounds),
                                ),
                              ],
                            ),
                            CustomScrollView(
                              primary: false,
                              slivers: <Widget>[
                                SliverPadding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 10, 20, 0),
                                  sliver: SliverGrid.count(
                                      crossAxisSpacing: 20,
                                      mainAxisSpacing: 10,
                                      crossAxisCount: 6,
                                      children: menusOnFont),
                                ),
                                SliverPadding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 10, 20, 30),
                                  sliver: SliverGrid.count(
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      crossAxisCount: 3,
                                      children: _layouts),
                                ),
                              ],
                            ),
                            _filterList(),
                          ])))
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _bottomSheetScrollButton(BuildContext context, _width, _height,
      _middleHeightBottomSheet, _maxHeightBottomSheet) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _sliderHeight = _sliderHeight == _initialSliderHeight
              ? _middleHeightBottomSheet
              : _sliderHeight == _maxHeightBottomSheet
                  ? _initialSliderHeight
                  : _maxHeightBottomSheet;
        });
      },
      onVerticalDragUpdate: (drag) {
        setState(() {
          _sliderHeight = drag.globalPosition.dy < _height - 30
              ? _height - drag.globalPosition.dy
              : _initialSliderHeight;
        });
      },
      onVerticalDragEnd: (drag) {
        setState(() {
          _sliderHeight = _sliderHeight > _height / 2
              ? _maxHeightBottomSheet
              : _sliderHeight > _height / 3
                  ? _middleHeightBottomSheet
                  : _initialSliderHeight;
        });
      },
      child: Container(
        width: _width,
        alignment: Alignment.center,
        child: Container(
          width: 140,
          height: 40,
          color: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
            child: RotatedBox(
              quarterTurns: _sliderHeight == _maxHeightBottomSheet ? 3 : 1,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Icon(
                  MdiIcons.chevronLeft,
                  color: Colors.white70,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _makeBackground(image) {
    return GestureDetector(
      onTap: () {
        setState(() {
          imageSource = "internet";
          backgroundImage = image;
        });
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.blueGrey,
          shape: BoxShape.rectangle,
          // border: Border.all(color:  backgroundImage == image ? Colors.white : Colors.transparent, width: 2, ),
        ),
        child: Stack(
          children: [
            CachedNetworkImage(
              placeholder: (context, url) => CircularProgressIndicator(),
              imageUrl: image + "?w=1200",
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  image:
                      DecorationImage(image: imageProvider, fit: BoxFit.cover),
                ),
              ),
              // ignore: avoid_unnecessary_containers
              errorWidget: (context, url, error) => Container(
                child: Icon(
                  Icons.error,
                  color: Colors.white70,
                ),
              ),
            ),
            backgroundImage == image
                ? Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.orange.withOpacity(0.3),
                    child: Center(
                      child: Icon(
                        MdiIcons.check,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  )
                : SizedBox()
          ],
        ),
      ),
    );
  }

  Widget _pickfromGallery() {
    return GestureDetector(
      onTap: () {
        setState(() {
          zoom = null;
        });
        getImageFromGallery();
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.rectangle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Icon(
              MdiIcons.imagePlus,
              size: 32,
              color: Colors.white,
            ),
            SizedBox(
              height: 2,
            ),
            Text(
              "Gallery",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            )
          ],
        ),
      ),
    );
  }

  Widget _fontView(fontStyle) {
    TextStyle font;
    switch (fontStyle["text"]) {
      case "Caveat":
        font =
            TextStyle(color: Colors.white, fontSize: 20, fontFamily: "Caveat");
        break;
      case "LatoLight":
        font = TextStyle(
            color: Colors.white, fontSize: 20, fontFamily: "LatoLight");
        break;
      case "LatoBold":
        font = TextStyle(
            color: Colors.white, fontSize: 20, fontFamily: "LatoBold");
        break;
      case "IndieFlower":
        font = TextStyle(
            color: Colors.white, fontSize: 20, fontFamily: "IndieFlower");
        break;
      case "Montserrat":
        font = TextStyle(
            color: Colors.white, fontSize: 20, fontFamily: "Montserrat");
        break;
      case "Satisfy":
        font =
            TextStyle(color: Colors.white, fontSize: 20, fontFamily: "Satisfy");
        break;
      case "SpecialElite":
        font = TextStyle(
            color: Colors.white, fontSize: 20, fontFamily: "SpecialElite");
        break;
      default:
        font =
            TextStyle(color: Colors.white, fontSize: 20, fontFamily: "Caveat");
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFont = fontStyle["text"];
          selectedTextstyle = TextStyle(
              color: quoteColor,
              fontSize: fontSize,
              fontFamily: fontStyle["text"]);
        });
      },
      child: selectedFont == fontStyle["text"]
          ? Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[800],
                borderRadius: BorderRadius.all(Radius.circular(0)),
                border: Border.all(
                    color: Colors.orange[800] ?? Colors.orange, width: 3),
              ),
              child: Text(
                fontStyle["text"],
                overflow: TextOverflow.fade,
                maxLines: 1,
                style: font,
              ),
            )
          : Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                  border: Border.all(color: Colors.orange, width: 0)),
              child: Text(
                fontStyle["text"],
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: font,
              ),
            ),
    );
  }

  takeScreenShot(BuildContext context) async {
    setState(() {
      showProgressOnGenerate = true;
    });
    RenderRepaintBoundary boundary = (previewContainer.currentContext
        ?.findRenderObject()) as RenderRepaintBoundary;
    double pixelRatio =
        MediaQuery.of(context).size.height / MediaQuery.of(context).size.width;

    ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();
    final directory = await getExternalStorageDirectory();
    var _file = directory?.path;
    String now = DateTime.now().toString();
    now = now.split(RegExp(r"(:|-)")).join("_");
    now = now.split(" ").join("_");
    now = now.split(".").join("_");
    String _filename = '$_file/q-$now.png';
    File imgFile = File(_filename);
    imgFile.writeAsBytesSync(pngBytes);

    // https://pub.dev/packages/image_gallery_saver
    // const MethodChannel _channel = MethodChannel('image_gallery_saver');
    // await _channel.invokeMethod('saveFileToGallery', _filename);

    setState(() {
      previewImage = _filename;
      showProgressOnGenerate = false;
      share();
    });
  }

  Widget _filterList() {
    return CustomScrollView(
      primary: false,
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverGrid.count(
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            crossAxisCount: 4,
            children: <Widget>[
              _filterNone(),
              _filterGrayScale(),
              _filterBrightBlack(),
              _filterBrightBlue(),
              _filterBrightYellow(),
              _filterSepia(),
              _filterKodaChrome(),
              _filterInversion(),
              _filterBrightGreen(),
              _filterBrightBlack(),
              _filterBrigh2Black(),
              _filterBrighMagenta(),
              _filterBrightFlorecent(),
              _filterBrightestBlack(),
              _filterLightpink(),
              _filterTest()
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterNone() {
    List<double> _matrix = [
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0
    ];
    return _filter(_matrix, "none");
  }

  Widget _filterGrayScale() {
    List<double> _matrix = [
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
    return _filter(_matrix, "grayscale");
  }

  Widget _filterInversion() {
    List<double> _matrix = [
      -1,
      0,
      0,
      0,
      255,
      0,
      -1,
      0,
      0,
      255,
      0,
      0,
      -1,
      0,
      255,
      0,
      0,
      0,
      1,
      0,
    ];
    return _filter(_matrix, "invert");
  }

  Widget _filterSepia() {
    List<double> _matrix = [
      0.393,
      0.769,
      0.189,
      0,
      0,
      0.349,
      0.686,
      0.168,
      0,
      0,
      0.272,
      0.534,
      0.131,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
    return _filter(_matrix, "sepia");
  }

  Widget _filterKodaChrome() {
    List<double> _matrix = [
      1.1285582396593525,
      -0.3967382283601348,
      -0.03992559172921793,
      0,
      63.72958762196502,
      -0.16404339962244616,
      1.0835251566291304,
      -0.05498805115633132,
      0,
      24.732407896706203,
      -0.16786010706155763,
      -0.5603416277695248,
      1.6014850761964943,
      0,
      35.62982807460946,
      0,
      0,
      0,
      1,
      0
    ];
    return _filter(_matrix, "kodachrome");
  }

  Widget _filterBrightYellow() {
    List<double> _matrix = [
      10,
      45,
      0,
      1,
      1,
      2,
      0,
      0,
      0,
      4,
      1,
      0,
      0,
      0,
      7,
      0,
      0,
      0,
      1,
      0
    ];
    return _filter(_matrix, "brightblack");
  }

  Widget _filterBrightBlack() {
    List<double> _matrix = [
      0,
      1,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      0
    ];
    return _filter(_matrix, "brightblack");
  }

  Widget _filterBrightBlue() {
    List<double> _matrix = [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      0
    ];
    return _filter(_matrix, "brightblue");
  }

  Widget _filterBrightGreen() {
    List<double> _matrix = [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      0
    ];
    return _filter(_matrix, "brightblue");
  }

  Widget _filterBrightFlorecent() {
    List<double> _matrix = [
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      0
    ];
    return _filter(_matrix, "brightflorecent");
  }

  Widget _filterBrightestBlack() {
    List<double> _matrix = [
      1,
      1,
      1,
      0,
      0,
      1,
      1,
      1,
      0,
      0,
      1,
      1,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0
    ];
    return _filter(_matrix, "brightestblack");
  }

  Widget _filterBrigh2Black() {
    List<double> _matrix = [
      0,
      1,
      1,
      0,
      0,
      0,
      1,
      1,
      0,
      0,
      0,
      1,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0
    ];
    return _filter(_matrix, "bright2black");
  }

  Widget _filterBrighMagenta() {
    List<double> _matrix = [
      0,
      0,
      1,
      1,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      1,
      1,
      0,
      0,
      0,
      0,
      1,
      0
    ];
    return _filter(_matrix, "brightmagenta");
  }

  Widget _filterLightpink() {
    List<double> _matrix = [
      0.45,
      0,
      1,
      0.5,
      .5,
      0.67,
      0.1,
      0.2,
      0,
      1,
      0,
      0,
      1,
      0.9,
      0,
      0,
      0,
      0,
      1,
      0
    ];
    return _filter(_matrix, "lightpink");
  }

  Widget _filterTest() {
    List<double> _matrix = [
      0,
      0,
      -1,
      0,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ];
    return _filter(_matrix, "test");
  }

  Widget _filter(_matrix, _filterName) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        image: DecorationImage(
          colorFilter: ColorFilter.matrix(_matrix),
          image: AssetImage('assets/filter.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: TextButton(
        child: SizedBox(),
        // color: Colors.transparent,
        onPressed: () {
          setState(() {
            filterApplied = _filterName;
            filterMatrix = _matrix;
          });
        },
      ),
    );
  }

  Future<String?> localPath() async {
    // make these changes in first launch of the app
    // check available directories
    // create an application directory too available path
    // store file path in share preferences  to save a file in shared preferences
    try {
      final directory = await getApplicationSupportDirectory();
      // List externalDirectory = await getExternalStorageDirectories();
      Directory(directory.path)
          .create(recursive: true)
          .then((Directory newdir) {
        // if error in directory creation
      });
      return directory.path;
    } catch (err) {
      return null;
    }
  }

  Widget lyricsText(_width, _height, context) {
    return Positioned(
      top: y,
      left: x,
      child: GestureDetector(
          onPanUpdate: (tap) {
            setState(() {
              if ((x + editBoxSize + tap.delta.dx - 100) < _width) {
                x += tap.delta.dx;
              }
              if ((y + tap.delta.dy) < _height) y += tap.delta.dy;
            });
          },
          onTap: () {
            showTextColorBox(context);
          },
          child: Container(
            width: editBoxSize,
            padding: EdgeInsets.all(10.0),
            child: Text(
              textToShare,
              style: selectedTextstyle,
              textAlign: textAlign,
            ),
          )),
    );
  }

  showEditBox(BuildContext context) {
    return showDialog(
        builder: (context) => AlertDialog(
              backgroundColor: Color.fromARGB(240, 200, 200, 200),
              title: Text("Edit Text"),
              // ignore: sized_box_for_whitespace
              content: Container(
                  height: 150,
                  child: ListView(
                    children: <Widget>[
                      TextField(
                        minLines: 3,
                        controller: textController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        autofocus: true,
                        decoration: InputDecoration(hintText: textToShare),
                        onChanged: (newVal) {
                          setState(() {
                            textToShare = newVal;
                          });
                        },
                      ),
                      Wrap(
                        alignment: WrapAlignment.end,
                        children: <Widget>[
                          // ignore: deprecated_member_use
                          TextButton(
                            child: Text('Done'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          )
                        ],
                      )
                    ],
                  )),
            ),
        context: context);
  }

  final List<Color> _customPickerColors = [
    Colors.white,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.indigoAccent,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.tealAccent,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.yellowAccent,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];

  void changeColor(Color color) {
    setState(() {
      quoteColor = color;
      currentPickerColor = color;
      selectedTextstyle = TextStyle(
          fontSize: fontSize, fontFamily: selectedFont, color: quoteColor);
    });
    Navigator.of(context).pop();
  }

  showTextColorBox(BuildContext context) {
    return showDialog(
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).backgroundColor.withOpacity(0.6),
        title: const Text('Quote Color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: currentPickerColor,
            onColorChanged: changeColor,
            availableColors: _customPickerColors,
          ),
        ),
      ),
      context: context,
    );
  }

  void share() {
    Share.shareXFiles([XFile(previewImage!)]);
  }

  Future getImageFromGallery() async {
    var image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        imageSource = "gallery";
        backgroundImage = image.path;
        zoom = ZoomableImage(
          FileImage(File(backgroundImage)),
          placeholder: Center(
            child: CircularProgressIndicator(),
          ),
          imageName: backgroundImage,
        );
        oldzoom = zoom;
      });
    } else if (oldzoom != null) {
      setState(() {
        zoom = oldzoom;
      });
    }
  }
}
