//
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'base_shader.dart';

class LiquidGlassLens extends BaseShader {
  final double distortion;
  final double refraction;
  final double reflectance;
  final double blur;
  final double noise;

  LiquidGlassLens({
    Key? key,
    required ui.Image? backgroundImage,
    this.distortion = 0.1,
    this.refraction = 0.2,
    this.reflectance = 0.3,
    this.blur = 0.0,
    this.noise = 0.03,
  }) : super(
          key: key,
          shaderAssetKey: 'shaders/liquid_glass_lens.frag',
          backgroundImage: backgroundImage,
        );

  @override
  void updateUniforms(FragmentShader shader, Size size, double time) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, distortion)
      ..setFloat(4, refraction)
      ..setFloat(5, reflectance)
      ..setFloat(6, blur)
      ..setFloat(7, noise);
  }
}
