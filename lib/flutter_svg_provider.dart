library flutter_svg_provider;

import 'dart:async';
import 'dart:ui' as ui show Codec, Image, Picture, ImageByteFormat;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class Svg extends ImageProvider<Svg> {
  final String asset;
  final double width;
  final double height;

  const Svg(this.asset, {this.width = 100, this.height = 100})
      : assert(asset != null),
        assert(width != null),
        assert(height != null);

  @override
  Future<Svg> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<Svg>(this);
  }

  @override
  ImageStreamCompleter load(Svg key, nil) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _loadAsync(Svg key) async {
    assert(key == this);

    var rawSvg = await rootBundle.loadString(asset);
    final DrawableRoot svgRoot = await svg.fromSvgString(rawSvg, rawSvg);
    final ui.Picture picture = svgRoot.toPicture(
      size: Size(
        width.toDouble(),
        height.toDouble(),
      ),
      clipToViewBox: false,
    );
    final ui.Image image = await picture.toImage(width, height);
    var imageData = await image.toByteData(format: ui.ImageByteFormat.png);

    return PaintingBinding.instance
        .instantiateImageCodec(imageData.buffer.asUint8List());
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final Svg typedOther = other;
    return asset == typedOther.asset &&
        width == typedOther.width &&
        height == typedOther.height;
  }

  @override
  int get hashCode => hashValues(asset.hashCode, 1.0);

  @override
  String toString() => '$runtimeType(${describeIdentity(asset)}, scale: 1.0)';
}
