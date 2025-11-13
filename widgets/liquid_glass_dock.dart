import 'package:flutter/material.dart';
import 'dart:ui';

class LiquidGlassDock extends StatefulWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;
  final List items;
  final ScrollController? scrollController;
  final bool hideOnScroll;

  const LiquidGlassDock({
    Key? key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.items,
    this.scrollController,
    this.hideOnScroll = true,
  }) : super(key: key);

  @override
  State createState() => _LiquidGlassDockState();
}

class _LiquidGlassDockState extends State<LiquidGlassDock>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation _slideAnimation;
  late Animation _opacityAnimation;
  bool _isVisible = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    widget.scrollController?.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!widget.hideOnScroll) return;
    final currentScroll = widget.scrollController?.offset ?? 0;
    final delta = currentScroll - _lastScrollOffset;
    if (delta > 5 && _isVisible) {
      setState(() => _isVisible = false);
      _animationController.forward();
    } else if (delta < -5 && !_isVisible) {
      setState(() => _isVisible = true);
      _animationController.reverse();
    }
    _lastScrollOffset = currentScroll;
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_handleScroll);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = MediaQuery.of(context).padding;
    final dockItemCount = widget.items.length;
    final dockFullWidth = MediaQuery.of(context).size.width - 32;
    final slotWidth = dockFullWidth / dockItemCount;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SlideTransition(
        position: Tween(
          begin: Offset.zero,
          end: const Offset(0, 1.2),
        ).animate(_slideAnimation),
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, padding.bottom > 0 ? 8 : 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    height: 82,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Colors.white.withOpacity(0.18), Colors.white.withOpacity(0.10)]
                            : [Colors.white.withOpacity(0.70), Colors.white.withOpacity(0.50)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Colors.white.withOpacity(isDark ? 0.35 : 0.60),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.50 : 0.12),
                          blurRadius: 35,
                          offset: const Offset(0, 15),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          left: widget.currentIndex * slotWidth,
                          top: 10,
                          child: Container(
                            width: slotWidth,
                            height: 62,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.14)]
                                    : [Colors.white.withOpacity(0.85), Colors.white.withOpacity(0.65)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(isDark ? 0.40 : 0.70),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(isDark ? 0.15 : 0.30),
                                  blurRadius: 15,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(
                            dockItemCount,
                            (index) => SizedBox(
                              width: slotWidth,
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
                ),
              ),
            ),
          ),
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
      splashColor: Colors.white.withOpacity(0.15),
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
                      color: item.activeColor.withOpacity(0.4),
                      blurRadius: 8,
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
