// [Codice da lucasxu0/liquid_glass/lib/shader_painter.dart, corretto]
import 'package:flutter/material.dart';
import 'dart:ui' as ui; // ✅ 1. AGGIUNTO IMPORT MANCANTE

class ShaderPainter extends CustomPainter {
  final ui.FragmentShader shader; // Tipo corretto
  final double time;
  final ui.Image backgroundImage;
  final Function(ui.FragmentShader, Size, double) updateUniforms; // Tipo corretto

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
