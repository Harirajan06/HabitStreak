import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  /// Renders a widget wrapped in a RepaintBoundary with [boundaryKey]
  /// to a PNG byte array sized to [width] x [height]. Returns null on failure.
  static Future<Uint8List?> exportWidgetToPng(GlobalKey boundaryKey,
      {int width = 1080, int height = 1080}) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Compute pixel ratio to match requested output size
      final logicalSize = boundary.size;
      final pixelRatio = width / logicalSize.width;

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      // propagate or return null
      rethrow;
    }
  }

  /// Exports the widget and immediately shares the resulting PNG using platform share sheet.
  static Future<void> exportAndShare(GlobalKey boundaryKey,
      {int width = 1080,
      int height = 1080,
      String? filename}) async {
    final bytes = await exportWidgetToPng(boundaryKey, width: width, height: height);
    if (bytes == null) throw Exception('Export failed');

    final dir = await getTemporaryDirectory();
    final name = filename ?? 'streakly_wrapped_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'My Habit Wrapped');
  }
}
