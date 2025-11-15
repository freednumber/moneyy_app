// [Codice adattato da 'widgets/liquid_glass_dock.dart' e 'lucasxu0/liquid_glass']
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
// ✅ 1. IMPORTA IL NUOVO WIDGET SHADER
import 'shader_helpers/liquid_glass_lens_shader.dart';

class LiquidGlassDock extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<DockItem> items;
  // ✅ 2. ACCETTA IL NOTIFIER DELLO SFONDO
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
  // Le animazioni per lo scroll non sono più necessarie
  // se il widget è sempre visibile in fondo.
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = MediaQuery.of(context).padding;
    final dockItemCount = widget.items.length;
    final dockFullWidth = MediaQuery.of(context).size.width - 32;
    final slotWidth = dockFullWidth / dockItemCount;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, padding.bottom > 0 ? 8 : 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        // ✅ 3. USARE 'AnimatedBuilder' PER ASCOLTARE L'IMMAGINE DI SFONDO
        child: AnimatedBuilder(
          animation: widget.backgroundImageNotifier,
          builder: (context, child) {
            // ✅ 4. SOSTITUIRE 'BackdropFilter' CON 'LiquidGlassLens'
            return LiquidGlassLens(
              backgroundImage: widget.backgroundImageNotifier.value,
              // Parametri per l'effetto vetro
              distortion: 0.1,
              refraction: 0.15,
              reflectance: 0.2,
              blur: isDark ? 2.0 : 1.0, // Sfocatura più forte in dark mode
              noise: 0.02,
              child: Container(
                height: 82,
                // Rimuoviamo 'decoration' (gradient, border, shadow)
                // perché lo shader ora disegna il vetro.
                // Mettiamo solo un bordo sottile SOPRA lo shader.
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.25 : 0.40),
                    width: 1.5,
                  ),
                  // Colore di fallback se lo shader fallisce
                  color: isDark ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.1),
                ),
                child: Stack(
                  children: [
                    // Indicatore item attivo
                    // (Ora è un vetro-nel-vetro)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      left: widget.currentIndex * slotWidth,
                      top: 10,
                      child: Container(
                        width: slotWidth,
                        height: 62,
                        decoration: BoxDecoration(
                          // Usiamo un vetro bianco standard
                          color: Colors.white.withOpacity(isDark ? 0.20 : 0.50),
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
                    // Lista di items
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
            );
          },
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
                // Colore verde dall'item
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

// Classe Dati per gli items
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
