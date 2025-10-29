import 'dart:ui';
import 'package:flutter/material.dart';

class GlassDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const GlassDock({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.04)]
                    : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.85),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DockItem(icon: Icons.home_rounded, index: 0, currentIndex: currentIndex, onTap: onTap),
                _DockItem(icon: Icons.receipt_long_rounded, index: 1, currentIndex: currentIndex, onTap: onTap),
                _DockItem(icon: Icons.bar_chart_rounded, index: 2, currentIndex: currentIndex, onTap: onTap),
                _DockItem(icon: Icons.sync_alt_rounded, index: 3, currentIndex: currentIndex, onTap: onTap),
                _DockItem(icon: Icons.settings_rounded, index: 4, currentIndex: currentIndex, onTap: onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _DockItem({required this.icon, required this.index, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool active = index == currentIndex;
    final Color activeColor = const Color(0xFF6366F1);
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: active ? activeColor.withOpacity(0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: active ? activeColor : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}
