// Versione ottimizzata con pattern glass
// TODO: Integrare con scan_receipt_page.dart esistente
// Pattern da applicare:
// 1. AppBar con BackdropFilter
// 2. Card selezione camera/gallery con glass
// 3. Preview immagine con container glass
// 4. Form risultati con card glass
// 5. Bottoni con glass effect

import 'package:flutter/material.dart';
import 'dart:ui';

class GlassReceiptHelper {
  static Widget buildGlassCard({
    required Widget child,
    required bool isDark,
    double blur = 12,
    double opacity = 0.08,
    double borderRadius = 20,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(opacity) : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.15) : Colors.white,
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  static Widget buildGlassButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(isDark ? 0.3 : 0.25),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white : color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
