import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Widget riutilizzabile per creare card con effetto liquid glass
/// Stile Apple con glassmorphism avanzato
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? glassColor;
  final double thickness;
  final double blur;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 30,
    this.padding,
    this.glassColor,
    this.thickness = 15,
    this.blur = 10,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultGlassColor = isDark
        ? const Color(0x1AFFFFFF) // Bianco trasparente per dark mode
        : const Color(0x33FFFFFF); // Bianco più opaco per light mode

    return GestureDetector(
      onTap: onTap,
      child: LiquidGlass.withOwnLayer(
        settings: LiquidGlassSettings(
          thickness: thickness,
          blur: blur,
          glassColor: glassColor ?? defaultGlassColor,
          lightIntensity: 1.2,
          outlineIntensity: 0.4,
          saturation: 1.3,
          refractiveIndex: 1.5,
          ambientStrength: 0.3,
        ),
        shape: LiquidRoundedSuperellipse(
          borderRadius: borderRadius,
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

/// Card liquid glass con effetto glow interattivo
class LiquidGlassCardWithGlow extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? glassColor;
  final Color? glowColor;
  final double thickness;
  final double blur;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const LiquidGlassCardWithGlow({
    super.key,
    required this.child,
    this.borderRadius = 30,
    this.padding,
    this.glassColor,
    this.glowColor,
    this.thickness = 15,
    this.blur = 10,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultGlassColor = isDark
        ? const Color(0x1AFFFFFF)
        : const Color(0x33FFFFFF);
    final defaultGlowColor = isDark
        ? Colors.white24
        : Colors.white38;

    return GestureDetector(
      onTap: onTap,
      child: LiquidStretch(
        stretch: 0.3,
        interactionScale: 1.02,
        child: LiquidGlass.withOwnLayer(
          settings: LiquidGlassSettings(
            thickness: thickness,
            blur: blur,
            glassColor: glassColor ?? defaultGlassColor,
            lightIntensity: 1.5,
            outlineIntensity: 0.5,
            saturation: 1.4,
            refractiveIndex: 1.5,
            ambientStrength: 0.4,
          ),
          shape: LiquidRoundedSuperellipse(
            borderRadius: borderRadius,
          ),
          child: GlassGlow(
            glowColor: glowColor ?? defaultGlowColor,
            glowRadius: 1.2,
            child: Container(
              width: width,
              height: height,
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Container liquid glass per raggruppare più widget
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? glassColor;
  final double thickness;
  final double blur;
  final double? width;
  final double? height;
  final Alignment alignment;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 30,
    this.padding,
    this.margin,
    this.glassColor,
    this.thickness = 15,
    this.blur = 10,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultGlassColor = isDark
        ? const Color(0x1AFFFFFF)
        : const Color(0x33FFFFFF);

    return Container(
      margin: margin,
      child: LiquidGlass.withOwnLayer(
        settings: LiquidGlassSettings(
          thickness: thickness,
          blur: blur,
          glassColor: glassColor ?? defaultGlassColor,
          lightIntensity: 1.3,
          outlineIntensity: 0.4,
          saturation: 1.3,
        ),
        shape: LiquidRoundedSuperellipse(
          borderRadius: borderRadius,
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(20),
          alignment: alignment,
          child: child,
        ),
      ),
    );
  }
}

/// Button con effetto liquid glass
class LiquidGlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? glassColor;
  final Color? glowColor;
  final double thickness;
  final double blur;

  const LiquidGlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.borderRadius = 25,
    this.padding,
    this.glassColor,
    this.glowColor,
    this.thickness = 12,
    this.blur = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultGlassColor = isDark
        ? const Color(0x2AFFFFFF)
        : const Color(0x44FFFFFF);
    final defaultGlowColor = isDark ? Colors.white30 : Colors.white54;

    return LiquidStretch(
      stretch: 0.5,
      interactionScale: 1.05,
      child: GestureDetector(
        onTap: onPressed,
        child: LiquidGlass.withOwnLayer(
          settings: LiquidGlassSettings(
            thickness: thickness,
            blur: blur,
            glassColor: glassColor ?? defaultGlassColor,
            lightIntensity: 1.8,
            outlineIntensity: 0.6,
            saturation: 1.5,
          ),
          shape: LiquidRoundedSuperellipse(
            borderRadius: borderRadius,
          ),
          child: GlassGlow(
            glowColor: glowColor ?? defaultGlowColor,
            glowRadius: 1.5,
            child: Container(
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
