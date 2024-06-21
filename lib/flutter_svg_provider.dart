library flutter_svg_provider;

import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui show Image;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Get svg string.
typedef SvgStringGetter = Future<String?> Function(SvgImageKey key);

/// An [Enum] of the possible image path sources.
enum SvgSource {
  file,
  asset,
  network,
  raw,
}

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
  /// Path to svg file or asset
  final String path;

  /// Size in logical pixels to render.
  /// Useful for [DecorationImage].
  /// If not specified, will use size from [Image].
  /// If [Image] not specifies size too, will use default size 100x100.
  final Size? size;

  /// Color to tint the SVG
  final Color? color;

  /// Source of svg image
  final SvgSource source;

  /// Http headers to access network svg
  /// Only for network svg
  final Map<String, String>? httpHeaders;

  /// Image scale.
  final double? scale;

  /// Get svg string.
  /// Override the default get method.
  /// When returning null, use the default method.
  final SvgStringGetter? svgGetter;

  /// Width and height can also be specified from [Image] constructor.
  /// Default size is 100x100 logical pixels.
  /// Different size can be specified in [Image] parameters
  const Svg(
    this.path, {
    this.size,
    this.scale,
    this.color,
    this.source = SvgSource.asset,
    this.httpHeaders,
    this.svgGetter,
  });

  @override
  Future<SvgImageKey> obtainKey(ImageConfiguration configuration) {
    final Color color = this.color ?? Colors.transparent;
    final double scale = this.scale ?? configuration.devicePixelRatio ?? 1.0;
    final double logicWidth = size?.width ?? configuration.size?.width ?? 100;
    final double logicHeight =
        size?.height ?? configuration.size?.height ?? 100;

    return SynchronousFuture<SvgImageKey>(
      SvgImageKey(
        path: path,
        scale: scale,
        color: color,
        source: source,
        httpHeaders: httpHeaders,
        pixelWidth: (logicWidth * scale).round(),
        pixelHeight: (logicHeight * scale).round(),
        svgGetter: svgGetter,
      ),
    );
  }

  @override
  ImageStreamCompleter loadImage(SvgImageKey key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(
      _loadAsync(key, getFilterColor(color)),
    );
  }

  static Future<String> _getSvgString(SvgImageKey key) async {
    if (key.svgGetter != null) {
      final rawSvg = await key.svgGetter!(key);
      if (rawSvg != null) {
        return rawSvg;
      }
    }
    switch (key.source) {
      case SvgSource.network:
        return await http.read(Uri.parse(key.path), headers: key.httpHeaders);
      case SvgSource.asset:
        return await rootBundle.loadString(key.path);
      case SvgSource.file:
        return await File(key.path).readAsString();
      case SvgSource.raw:
        return key.path;
    }
  }

  static Future<ImageInfo> _loadAsync(SvgImageKey key, Color color) async {
    final rawSvg = await _getSvgString(key);
    final pictureInfo = await vg.loadPicture(
      SvgStringLoader(rawSvg, theme: SvgTheme(currentColor: color)),
      null,
      clipViewbox: false,
    );

    try {
      final image = kIsWeb
          ? await pictureInfo.picture.toImage(
              pictureInfo.size.width.round(),
              pictureInfo.size.height.round(),
            )
          : pictureInfo.picture.toImageSync(
              pictureInfo.size.width.round(),
              pictureInfo.size.height.round(),
            );
      return ImageInfo(
        image: image,
      );
    } finally {
      // Dispose of the Picture to release resources
      pictureInfo.picture.dispose();
    }
  }

  // Note: == and hashCode not overrided as changes in properties
  // (width, height and scale) are not observable from the here.
  // [SvgImageKey] instances will be compared instead.
  @override
  String toString() => '$runtimeType(${describeIdentity(path)})';

  // Running on web with Colors.transparent may throws the exception `Expected a value of type 'SkDeletable', but got one of type 'Null'`.
  static Color getFilterColor(color) {
    if (kIsWeb && color == Colors.transparent) {
      return const Color(0x01ffffff);
    } else {
      return color ?? Colors.transparent;
    }
  }
}

@immutable
class SvgImageKey {
  const SvgImageKey({
    required this.path,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.scale,
    required this.source,
    this.httpHeaders,
    this.color,
    this.svgGetter,
  });

  /// Path to svg asset.
  final String path;

  /// Width in physical pixels.
  /// Used when raterizing.
  final int pixelWidth;

  /// Height in physical pixels.
  /// Used when raterizing.
  final int pixelHeight;

  /// Color to tint the SVG
  final Color? color;

  /// Image source.
  final SvgSource source;

  /// Http headers to access network svg
  /// Only for network svg
  final Map<String, String>? httpHeaders;

  /// Used to calculate logical size from physical, i.e.
  /// logicalWidth = [pixelWidth] / [scale],
  /// logicalHeight = [pixelHeight] / [scale].
  /// Should be equal to [MediaQueryData.devicePixelRatio].
  final double scale;

  /// Svg string getter.
  final SvgStringGetter? svgGetter;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is SvgImageKey &&
        other.path == path &&
        other.pixelWidth == pixelWidth &&
        other.pixelHeight == pixelHeight &&
        other.scale == scale &&
        other.source == source &&
        mapEquals(other.httpHeaders, httpHeaders) && // Compare httpHeaders
        other.svgGetter == svgGetter &&
        other.color == color;
  }

  @override
  int get hashCode =>
      Object.hash(path, pixelWidth, pixelHeight, scale, source, httpHeaders, svgGetter, color);

  @override
  String toString() => '${objectRuntimeType(this, 'SvgImageKey')}'
      '(path: "$path", pixelWidth: $pixelWidth, pixelHeight: $pixelHeight, color: $color, scale: $scale, source: $source, httpHeaders: $httpHeaders)';
}
