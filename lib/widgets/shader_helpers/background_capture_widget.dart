//
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

class BackgroundCaptureWidget extends StatefulWidget {
  final Widget child;
  final ValueNotifier<ui.Image?> backgroundNotifier;

  const BackgroundCaptureWidget({
    Key? key,
    required this.child,
    required this.backgroundNotifier,
  }) : super(key: key);

  @override
  BackgroundCaptureWidgetState createState() => BackgroundCaptureWidgetState();
}

class BackgroundCaptureWidgetState extends State<BackgroundCaptureWidget> {
  final GlobalKey _boundaryKey = GlobalKey();

  void capture() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        RenderRepaintBoundary boundary =
            _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 1.0);
        if (mounted) {
          widget.backgroundNotifier.value = image;
        }
      } catch (e) {
        debugPrint("Errore cattura sfondo: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _boundaryKey,
      child: widget.child,
    );
  }
}
