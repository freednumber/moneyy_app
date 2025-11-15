//
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class ShaderPainter extends CustomPainter {
  final FragmentShader shader;
  final double time;
  final ui.Image backgroundImage;
  final Function(FragmentShader, Size, double) updateUniforms;

  ShaderPainter({
    required this.shader,
    required this.time,
    required this.backgroundImage,
    required this.updateUniforms,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setImageSampler(0, backgroundImage);
    updateUniforms(shader, size, time);
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
