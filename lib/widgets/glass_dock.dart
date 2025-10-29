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
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                        Colors.black.withOpacity(0.1),
                      ]
                    : [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.8),
                        Colors.grey[50]!.withOpacity(0.9),
                      ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.9),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.6 : 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(isDark ? 0.1 : 0.8),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DockItem(
                  icon: Icons.home_rounded,
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  isDark: isDark,
                ),
                _DockItem(
                  icon: Icons.receipt_long_rounded,
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  isDark: isDark,
                ),
                _DockItem(
                  icon: Icons.qr_code_scanner_rounded,
                  index: 2,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  isDark: isDark,
                  isCenter: true,
                ),
                _DockItem(
                  icon: Icons.analytics_rounded,
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  isDark: isDark,
                ),
                _DockItem(
                  icon: Icons.person_rounded,
                  index: 4,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  isDark: isDark,
                ),
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
  final bool isDark;
  final bool isCenter;
  
  const _DockItem({
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = index == currentIndex;
    final Color activeColor = isCenter ? const Color(0xFF00BFFF) : const Color(0xFF6366F1);
    
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(active ? 12 : 8),
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      colors: isCenter
                          ? [const Color(0xFF00BFFF), const Color(0xFF1E90FF)]
                          : [activeColor.withOpacity(0.9), activeColor.withOpacity(0.7)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(20),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: activeColor.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: isCenter && active ? 28 : 24,
              color: active
                  ? Colors.white
                  : isDark
                      ? Colors.white.withOpacity(0.6)
                      : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}