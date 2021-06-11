library flutter_svg_provider;

import 'dart:async';
import 'dart:ui' as ui show Image, Picture;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Rasterizes given svg picture for displaying in [Image] widget:
///
/// ```dart
/// Image(
///   width: 32,
///   height: 32,
///   image: Svg('assets/my_icon.svg'),
/// )
/// ```
class Svg extends ImageProvider<SvgImageKey> {
  /// Path to svg file asset
  final String asset;

  /// Size in logical pixels to render.
  /// Useful for [DecorationImage].
  /// If not specified, will use size from [Image].
  /// If [Image] not specifies size too, will use default size 100x100.
  final Size? size; // nullable

  /// Color to tint the SVG
  final Color? color;

  /// Width and height can also be specified from [Image] constrictor.
  /// Default size is 100x100 logical pixels.
  /// Different size can be specified in [Image] parameters
  const Svg(this.asset, {this.size, this.color});

  @override
  Future<SvgImageKey> obtainKey(ImageConfiguration configuration) {
    final double logicWidth = size?.width ?? configuration.size?.width ?? 100;
    final double logicHeight = size?.height ?? configuration.size?.width ?? 100;
    final double scale = configuration.devicePixelRatio ?? 1.0;
    final Color color = this.color ?? Colors.transparent;

    return SynchronousFuture<SvgImageKey>(
      SvgImageKey(
          assetName: asset,
          pixelWidth: (logicWidth * scale).round(),
          pixelHeight: (logicHeight * scale).round(),
          scale: scale,
          color: color),
    );
  }

  @override
  ImageStreamCompleter load(SvgImageKey key, nil) {
    return OneFrameImageStreamCompleter(
      _loadAsync(key),
    );
  }

  static Future<ImageInfo> _loadAsync(SvgImageKey key) async {
    final String rawSvg = await rootBundle.loadString(key.assetName);
    final DrawableRoot svgRoot = await svg.fromSvgString(rawSvg, key.assetName);
    final ui.Picture picture = svgRoot.toPicture(
      size: Size(
        key.pixelWidth.toDouble(),
        key.pixelHeight.toDouble(),
      ),
      clipToViewBox: false,
      colorFilter: ColorFilter.mode(key.color, BlendMode.srcATop),
    );
    final ui.Image image = await picture.toImage(
      key.pixelWidth,
      key.pixelHeight,
    );
    return ImageInfo(
      image: image,
      scale: key.scale,
    );
  }

  // Note: == and hashCode not overrided as changes in properties
  // (width, height and scale) are not observable from the here.
  // [SvgImageKey] instances will be compared instead.

  @override
  String toString() => '$runtimeType(${describeIdentity(asset)})';
}

@immutable
class SvgImageKey {
  const SvgImageKey({
    required this.assetName,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.scale,
    required this.color,
  });

  /// Path to svg asset.
  final String assetName;

  /// Width in physical pixels.
  /// Used when raterizing.
  final int pixelWidth;

  /// Height in physical pixels.
  /// Used when raterizing.
  final int pixelHeight;

  /// Color to tint the SVG
  final Color color;

  /// Used to calculate logical size from physical, i.e.
  /// logicalWidth = [pixelWidth] / [scale],
  /// logicalHeight = [pixelHeight] / [scale].
  /// Should be equal to [MediaQueryData.devicePixelRatio].
  final double scale;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SvgImageKey &&
        other.assetName == assetName &&
        other.pixelWidth == pixelWidth &&
        other.pixelHeight == pixelHeight &&
        other.scale == scale;
  }

  @override
  int get hashCode => hashValues(assetName, pixelWidth, pixelHeight, scale);

  @override
  String toString() => '${objectRuntimeType(this, 'SvgImageKey')}'
      '(assetName: "$assetName", pixelWidth: $pixelWidth, pixelHeight: $pixelHeight, scale: $scale)';
}
