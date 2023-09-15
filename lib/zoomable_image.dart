import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// source : https://raw.githubusercontent.com/perlatus/flutter_zoomable_image/master/lib/src/zoomable_image.dart
// Given a canvas and an image, determine what size the image should be to be
// contained in but not exceed the canvas while preserving its aspect ratio.
// Size _containmentSize(Size canvas, Size image) {}

class ZoomableImage extends StatefulWidget {
  final ImageProvider image;
  final ColorFilter? colorFilter;
  final double maxScale;
  final double minScale;
  final GestureTapCallback? onTap;
  final Color backgroundColor;
  final Widget placeholder;
  final String imageName;

  ZoomableImage(
    this.image, {
    Key? key,
    // @deprecated double? scale,
    double? scale,

    /// Maximum ratio to blow up image pixels. A value of 2.0 means that the
    /// a single device pixel will be rendered as up to 4 logical pixels.
    this.maxScale = 2.0,
    this.minScale = 0.0,
    this.onTap,
    this.backgroundColor = Colors.black,
    this.colorFilter,
    required this.imageName,

    /// Placeholder widget to be used while [image] is being resolved.
    required this.placeholder,
  }) : super(key: key);

  @override
  _ZoomableImageState createState() => _ZoomableImageState();
}

// See /flutter/examples/layers/widgets/gestures.dart
class _ZoomableImageState extends State<ZoomableImage> {
  late ImageStream _imageStream;
  late ui.Image _image;
  late Size _imageSize;
  // String _imageName;
  late ColorFilter _colorFilter;

  late Offset _startingFocalPoint;

  late Offset _previousOffset;
  late Offset _offset; // where the top left corner of the image is drawn

  late double _previousScale;
  late double _scale; // multiplier applied to scale the full image

  late Orientation _previousOrientation;

  late Size _canvasSize;

  void _centerAndScaleImage() {
    _imageSize = Size(
      _image.width.toDouble(),
      _image.height.toDouble(),
    );

    _scale = math.min(
      _canvasSize.width / _imageSize.width,
      _canvasSize.height / _imageSize.height,
    );
    Size fitted = Size(
      _imageSize.width * _scale,
      _imageSize.height * _scale,
    );

    Offset delta = (_canvasSize - fitted) as Offset;
    _offset = delta / 2.0; // Centers the image
  }

  Function() _handleDoubleTap(BuildContext ctx) {
    return () {
      double newScale = _scale * 2;
      if (newScale > widget.maxScale) {
        _centerAndScaleImage();
        setState(() {});
        return;
      }

      // We want to zoom in on the center of the screen.
      // Since we're zooming by a factor of 2, we want the offset to be twice
      // as far from the center in both width and height than it is now.
      Offset center = ctx.size!.center(Offset.zero);
      Offset newOffset = _offset - (center - _offset);

      setState(() {
        _scale = newScale;
        _offset = newOffset;
      });
    };
  }

  void _handleScaleStart(ScaleStartDetails d) {
    print("starting scale at ${d.focalPoint} from $_offset $_scale");
    _startingFocalPoint = d.focalPoint;
    _previousOffset = _offset;
    _previousScale = _scale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails d) {
    double newScale = _previousScale * d.scale;
    if (newScale > widget.maxScale || newScale < widget.minScale) {
      return;
    }

    // Ensure that item under the focal point stays in the same place despite zooming
    final Offset normalizedOffset =
        (_startingFocalPoint - _previousOffset) / _previousScale;
    final Offset newOffset = d.focalPoint - normalizedOffset * newScale;

    setState(() {
      _scale = newScale;
      _offset = newOffset;
    });
  }

  @override
  Widget build(BuildContext ctx) {
    Widget paintWidget() {
      return CustomPaint(
        child: Container(color: widget.backgroundColor),
        foregroundPainter: _ZoomableImagePainter(
            image: _image,
            imageWidget: widget.image,
            offset: _offset,
            scale: _scale,
            colorFilteer: _colorFilter,
            imageName: widget.imageName),
      );
    }

    // ignore: unnecessary_null_comparison
    if (_image == null) {
      // return widget.placeholder ?? Center(child: CircularProgressIndicator());
      return widget.placeholder;
    }

    return LayoutBuilder(builder: (ctx, constraints) {
      Orientation orientation = MediaQuery.of(ctx).orientation;
      if (orientation != _previousOrientation) {
        _previousOrientation = orientation;
        _canvasSize = constraints.biggest;
        _centerAndScaleImage();
      }

      return GestureDetector(
        child: paintWidget(),
        onTap: widget.onTap,
        onDoubleTap: _handleDoubleTap(ctx),
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
      );
    });
  }

  @override
  void didChangeDependencies() {
    _resolveImage();
    super.didChangeDependencies();
  }

  @override
  void reassemble() {
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  // ImageStreamListener _handleImageLoaded(ImageInfo info, bool synchronousCall) {
  //   print("image loaded: $info");
  //   setState(() {
  //     _image = info.image;
  //   });
  // }

  void _resolveImage() {
    _imageStream = widget.image.resolve(createLocalImageConfiguration(context));
    // final ImageListener listener = (ImageInfo image, bool synchronousCall) { };
    _imageStream.addListener(
        ImageStreamListener((ImageInfo info, bool synchronousCall) {
      setState(() {
        _image = info.image;
      });
    }));
  }

  @override
  void dispose() {
//    _imageStream.removeListener(_handleImageLoaded);
    super.dispose();
  }
}

class _ZoomableImagePainter extends CustomPainter {
  const _ZoomableImagePainter(
      {required this.image,
      required this.offset,
      required this.scale,
      required this.colorFilteer,
      required this.imageName,
      required this.imageWidget});

  final ui.Image image;
  final Offset offset;
  final double scale;
  final ColorFilter colorFilteer;
  final String imageName;
  final ImageProvider imageWidget;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    Size targetSize = imageSize * scale;
    paintImage(
        canvas: canvas,
        rect: offset & targetSize,
        image: image,
        fit: BoxFit.fill,
        colorFilter: colorFilteer);
  }

  @override
  bool shouldRepaint(_ZoomableImagePainter old) {
    return old.imageName != imageName ||
        old.image != image ||
        old.offset != offset ||
        old.scale != scale;
  }
}
