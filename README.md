# flutter_svg_provider

A Flutter package for using svg in `Image` widget via custom `ImageProvider`.

Svg is parsed using flutter_svg dependency.

## Getting started

```dart
import 'package:flutter_svg_provider/flutter_svg_provider.dart';

final img1 = Image(
  width: 32,
  height: 32,
  image: Svg('assets/my_icon.svg'),
)
final img2 = Image(
  width: 32,
  height: 32,
  image: Svg('<svg>...</svg>',source: SvgSource.raw),
)
```
