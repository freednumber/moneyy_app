//
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'shader_painter.dart';

abstract class BaseShader extends StatefulWidget {
  final String shaderAssetKey;
  final ui.Image? backgroundImage;

  const BaseShader({
    Key? key,
    required this.shaderAssetKey,
    this.backgroundImage,
  }) : super(key: key);

  @override
  BaseShaderState createState() => BaseShaderState();

  void updateUniforms(FragmentShader shader, Size size, double time);
}

class BaseShaderState extends State<BaseShader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  FragmentShader? _shader;

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
      final program = await ui.FragmentProgram.fromAsset(widget.shaderAssetKey);
      _shader = program.fragmentShader();
      setState(() {});
    } catch (e) {
      debugPrint('Errore caricamento shader: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null || widget.backgroundImage == null) {
      return const SizedBox.shrink();
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
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
