import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

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
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _DockBackground(isDark: isDark),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _DockButton(icon: Icons.home_rounded, index: 0, currentIndex: currentIndex, onTap: onTap, isDark: isDark),
              _DockButton(icon: Icons.receipt_long_rounded, index: 1, currentIndex: currentIndex, onTap: onTap, isDark: isDark),
              _CenterScanButton(active: currentIndex == 2, onTap: () => onTap(2)),
              _DockButton(icon: Icons.analytics_rounded, index: 3, currentIndex: currentIndex, onTap: onTap, isDark: isDark),
              _DockButton(icon: Icons.person_rounded, index: 4, currentIndex: currentIndex, onTap: onTap, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _DockBackground extends StatelessWidget {
  final bool isDark;
  const _DockBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
                  ? [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.04)]
                  : [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.9), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(isDark ? 0.55 : 0.15), blurRadius: 40, offset: const Offset(0, 20)),
              BoxShadow(color: Colors.white.withOpacity(isDark ? 0.12 : 0.8), blurRadius: 10, offset: const Offset(0, -5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  const _DockButton({required this.icon, required this.index, required this.currentIndex, required this.onTap, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final bool active = index == currentIndex;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF6366F1).withOpacity(0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 24,
              color: active ? const Color(0xFF6366F1) : (isDark ? Colors.white.withOpacity(0.6) : Colors.grey.shade700),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterScanButton extends StatefulWidget {
  final bool active;
  final VoidCallback onTap;
  const _CenterScanButton({required this.active, required this.onTap});
  @override
  State<_CenterScanButton> createState() => _CenterScanButtonState();
}

class _CenterScanButtonState extends State<_CenterScanButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = const Color(0xFF00BFFF);
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow pulsante stile Just Eat
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final v = 1 + (_ctrl.value * 0.6);
              return Container(
                width: 64 * v,
                height: 64 * v,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: base.withOpacity(0.12 * (1 - _ctrl.value)),
                  boxShadow: [
                    BoxShadow(color: base.withOpacity(0.40), blurRadius: 28, spreadRadius: 1),
                  ],
                ),
              );
            },
          ),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00BFFF)),
            child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}
