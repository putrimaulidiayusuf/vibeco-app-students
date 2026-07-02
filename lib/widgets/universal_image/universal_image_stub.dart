import 'package:flutter/material.dart';

Widget createUniversalImage({
  required String imageUrl,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  return Image.network(
    imageUrl,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
