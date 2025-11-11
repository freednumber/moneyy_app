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

class _LiquidGlassDockState extends State<LiquidGlassDock> with SingleTickerProviderStateMixin {
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
              padding: EdgeInsets.fromLTRB(12, 8, 12, padding.bottom > 0 ? 8 : 16),
              child: _buildLiquidGlassDock(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidGlassDock(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 75,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.06)]
                  : [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.15)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.25 : 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Animated background highlight
              AnimatedBuilder(
                animation: Listenable.merge([]),
                builder: (context, child) {
                  double highlightLeft = 8 + (widget.currentIndex * ((MediaQuery.of(context).size.width - 32) / widget.items.length));
                  return Positioned(
                    left: highlightLeft,
                    top: 8,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      width: (MediaQuery.of(context).size.width - 32) / widget.items.length - 16,
                      height: 59,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isDark ? 0.15 : 0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(isDark ? 0.3 : 0.45),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(isDark ? 0.1 : 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Navigation items
              Row(
                children: List.generate(
                  widget.items.length,
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
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.transparent,
      child: Center(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 250),
          scale: isSelected ? 1.2 : 1.0,
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: isSelected ? 28 : 24,
                color: isSelected
                    ? item.activeColor
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              if (item.label != null) ...[
                const SizedBox(height: 4),
                Text(
                  item.label!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? item.activeColor
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
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
