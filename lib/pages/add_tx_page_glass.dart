// Versione ottimizzata con pattern glass
// TODO: Integrare con add_tx_page.dart esistente
// Pattern da applicare:
// 1. AppBar con BackdropFilter
// 2. Form fields con container glass
// 3. Category selector con chip glass
// 4. Date/time picker con glass
// 5. Save button con glass effect

import 'package:flutter/material.dart';
import 'dart:ui';

class GlassAddTxHelper {
  static Widget buildGlassFormCard({
    required Widget child,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
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

  static Widget buildGlassCategoryChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(isDark ? 0.25 : 0.15)
                  : (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? color.withOpacity(0.5)
                    : Colors.white.withOpacity(isDark ? 0.1 : 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: isSelected ? color : (isDark ? Colors.white70 : Colors.grey[600]), size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? (isDark ? Colors.white : color) : (isDark ? Colors.white70 : Colors.grey[600]),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
