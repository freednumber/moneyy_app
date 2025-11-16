// [Codice da lucasxu0/liquid_glass/lib/base_shader.dart, corretto]
import 'package:flutter/material.dart';
import 'dart:ui' as ui; // ✅ 1. AGGIUNTO IMPORT MANCANTE
import 'shader_painter.dart';

abstract class BaseShader extends StatefulWidget {
  final String shaderAssetKey;
  final ui.Image? backgroundImage;
  final Widget child; // ✅ 2. AGGIUNTO 'child'

  const BaseShader({
    Key? key,
    required this.shaderAssetKey,
    this.backgroundImage,
    required this.child, // ✅ 3. AGGIUNTO 'child' AL COSTRUTTORE
  }) : super(key: key);

  @override
  BaseShaderState createState() => BaseShaderState();

  void updateUniforms(ui.FragmentShader shader, Size size, double time);
}

class BaseShaderState extends State<BaseShader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _loadShader();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset(widget.shaderAssetKey);
      _shader = program.fragmentShader();
      setState(() {});
    } catch (e) {
      debugPrint('Errore caricamento shader: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null || widget.backgroundImage == null) {
      // Mostra il figlio anche se lo shader non è caricato
      // per evitare che gli item spariscano
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ShaderPainter(
            shader: _shader!,
            time: _controller.value * 10,
            backgroundImage: widget.backgroundImage!,
            updateUniforms: widget.updateUniforms,
          ),
          // ✅ 4. PASSA IL 'child' ALLA 'CustomPaint'
          child: widget.child,
        );
      },
    );
  }
}
