import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class LiquidGlassDock extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<DockItem> items;
  final ValueNotifier<ui.Image?> backgroundImageNotifier;

  const LiquidGlassDock({
    Key? key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.items,
    required this.backgroundImageNotifier,
  }) : super(key: key);

  @override
  State createState() => _LiquidGlassDockState();
}

class _LiquidGlassDockState extends State<LiquidGlassDock> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = MediaQuery.of(context).padding;
    final dockItemCount = widget.items.length;
    final dockFullWidth = MediaQuery.of(context).size.width * 0.85;
    final slotWidth = dockFullWidth / dockItemCount;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width * 0.075,
        8,
        MediaQuery.of(context).size.width * 0.075,
        padding.bottom > 0 ? 8 : 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Effetto Liquid Glass con BackdropFilter
            BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: isDark ? 20.0 : 15.0,
                sigmaY: isDark ? 20.0 : 15.0,
              ),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.3 : 0.5),
                    width: 2.0,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withOpacity(0.1),
                            Colors.black.withOpacity(0.15),
                          ]
                        : [
                            Colors.white.withOpacity(0.35),
                            Colors.white.withOpacity(0.2),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 25,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            // Contenuto dock
            Container(
              height: 70,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    left: widget.currentIndex * slotWidth,
                    top: 9,
                    child: Container(
                      width: slotWidth,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isDark ? 0.25 : 0.60),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(isDark ? 0.5 : 0.8),
                          width: 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(isDark ? 0.2 : 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(
                      dockItemCount,
                      (index) => Expanded(
                        child: _buildDockItem(
                          item: widget.items[index],
                          isSelected: widget.currentIndex == index,
                          onTap: () => widget.onIndexChanged(index),
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockItem({
    required DockItem item,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      splashColor: Colors.white.withOpacity(0.2),
      highlightColor: Colors.transparent,
      child: Center(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 300),
          scale: isSelected ? 1.15 : 1.0,
          curve: Curves.easeOutCubic,
          child: Icon(
            item.icon,
            size: isSelected ? 30 : 26,
            color: isSelected
                ? item.activeColor
                : (isDark ? Colors.grey[300] : Colors.grey[700]),
            shadows: isSelected
                ? [
                    Shadow(
                      color: item.activeColor.withOpacity(0.5),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class DockItem {
  final IconData icon;
  final Color activeColor;
  final String? label;
  
  DockItem({
    required this.icon,
    required this.activeColor,
    this.label,
  });
}
