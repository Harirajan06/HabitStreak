import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class IconRenderer {
  static Future<Uint8List?> renderIconToPng(IconData icon, Color color,
      {double size = 100}) async {
    try {
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      final double sizePx = size;

      final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );

      textPainter.text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: sizePx,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      );

      textPainter.layout();

      // Center the icon on the canvas
      final double xCenter = (sizePx - textPainter.width) / 2;
      final double yCenter = (sizePx - textPainter.height) / 2;

      textPainter.paint(canvas, Offset(xCenter, yCenter));

      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image image =
          await picture.toImage(sizePx.toInt(), sizePx.toInt());
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error rendering icon: $e");
      return null;
    }
  }
}
