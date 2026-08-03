import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ImageAssetView extends StatelessWidget {
  const ImageAssetView(
      {Key? key,
      required this.path,
      this.height,
      this.width,
      this.size,
      this.color,
      this.fit});

  final String path;
  final double? height;
  final double? width;
  final double? size;
  final Color? color;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    if (path.contains('.svg')) {
      return SvgPicture.asset(
        path,
        height: size ?? height,
        width: size ?? width,
        color: color,
        fit: fit == null ? BoxFit.contain : fit!,
      );
    } else {
      return Image.asset(
        path,
        height: size ?? height,
        width: size ?? width,
        fit: fit == null ? BoxFit.contain : fit!,
      );
    }
  }
}
