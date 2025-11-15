import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlassDock extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onCategoryChanged;
  
  const LiquidGlassDock({
    Key? key,
    required this.currentIndex,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  _LiquidGlassDockState createState() => _LiquidGlassDockState();
}

class _LiquidGlassDockState extends State<LiquidGlassDock> {
  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.home_rounded, 'label': 'Home', 'color': Color(0xFFFF6B35)},
    {'icon': Icons.calendar_month, 'label': 'Planning', 'color': Color(0xFF00C853)},
    {'icon': Icons.bar_chart_rounded, 'label': 'Reports', 'color': Color(0xFF2979FF)},
    {'icon': Icons.settings_rounded, 'label': 'Settings', 'color': Color(0xFFAA00FF)},
  ];

  double _waveValue = 0.0;

  @override
  void initState() {
    super.initState();
    _startWaveAnimation();
  }

  void _startWaveAnimation() {
    Future.doWhile(() async {
      if (!mounted) return false;
      await Future.delayed(Duration(milliseconds: 60));
      if (!mounted) return false;
      setState(() {
        _waveValue = (_waveValue + 0.015) % 1.0;
      });
      return true;
    });
  }

  void _onItemTap(int index) {
    if (index != widget.currentIndex) {
      widget.onCategoryChanged(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      height: 75 + bottomPadding, // ✅ RIDOTTO ALTEZZA
      child: Stack(
        children: [
          // SFONDO COMPATTO
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding,
            child: Container(
              height: 65, // ✅ RIDOTTA ALTEZZA
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                    ? [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ]
                    : [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.12),
                        Colors.transparent,
                      ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.15 : 0.25),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: CustomPaint(
                    painter: _LiquidWavePainter(
                      waveValue: _waveValue,
                      activeIndex: widget.currentIndex,
                      itemCount: _categories.length,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // ITEMS COMPATTI
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding,
            child: Container(
              height: 65,
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: List.generate(_categories.length, (index) {
                  final category = _categories[index];
                  final isActive = index == widget.currentIndex;
                  
                  return Expanded(
                    child: _CompactDockItem(
                      icon: category['icon'],
                      label: category['label'],
                      color: category['color'],
                      isActive: isActive,
                      waveValue: _waveValue,
                      onTap: () => _onItemTap(index),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactDockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final double waveValue;
  final VoidCallback onTap;
  
  const _CompactDockItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.waveValue,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ICONA COMPATTA
            Stack(
              alignment: Alignment.center,
              children: [
                // EFFETTO ONDA
                if (isActive)
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withOpacity(0.3),
                          color.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                
                // ICONA PRINCIPALE
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isActive 
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.9),
                            color.withOpacity(0.6),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                    border: Border.all(
                      color: isActive 
                        ? Colors.white.withOpacity(0.6)
                        : Colors.white.withOpacity(0.2),
                      width: isActive ? 1.5 : 1.0,
                    ),
                    boxShadow: isActive 
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                  ),
                  child: Icon(
                    icon,
                    size: isActive ? 20 : 18,
                    color: isActive ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[600]),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 4),
            
            // LABEL CORRETTA (SENZA TEXT SHADOW PROBLEMATICO)
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive 
                    ? color 
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  // ✅ RIMOSSO TEXT SHADOW CHE CAUSAVA ERRORI
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiquidWavePainter extends CustomPainter {
  final double waveValue;
  final int activeIndex;
  final int itemCount;
  
  _LiquidWavePainter({
    required this.waveValue,
    required this.activeIndex,
    required this.itemCount,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // FORMA ONDULATA
    final path = Path();
    final waveHeight = 6.0;
    final waveFrequency = 0.03;
    
    path.moveTo(0, size.height);
    path.lineTo(0, waveHeight);
    
    for (double x = 0; x <= size.width; x += 2) {
      final y = waveHeight + sin((x * waveFrequency) + (waveValue * 2 * pi)) * waveHeight;
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.close();
    
    // ONDA PRINCIPALE
    final wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, wavePaint);
    
    // EFFETTO ATTIVO
    final activeItemWidth = size.width / itemCount;
    final activeItemCenter = (activeIndex * activeItemWidth) + (activeItemWidth / 2);
    
    final activePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.4 * (0.5 + waveValue * 0.5)),
          Colors.white.withOpacity(0.1 * (0.5 + waveValue * 0.5)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(activeItemCenter, waveHeight),
        radius: 20 * (0.5 + waveValue * 0.5),
      ))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(activeItemCenter, waveHeight),
      15 * (0.5 + waveValue * 0.5),
      activePaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) {
    return waveValue != oldDelegate.waveValue ||
           activeIndex != oldDelegate.activeIndex;
  }
}