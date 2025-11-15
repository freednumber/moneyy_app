import 'package:flutter/material.dart';
// Assicurati che questo percorso sia corretto per la tua struttura di cartelle
import 'package:moneyy_app/widgets/liquid_glass_dock.dart';

class ShellScaffold extends StatefulWidget {
  final List<Widget> pages;
  const ShellScaffold({super.key, required this.pages});

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold> {
  int _index = 0;

  // 1. Definisci qui le tue categorie con la palette verde
  // Le icone sono prese dal tuo file 'lib/liquid_glass_dock.dart'
  final List<DockItem> _dockItems = [
    DockItem(
      icon: Icons.home_rounded,
      label: 'Home',
      // Tonalità di verde 1
      activeColor: Color(0xFF69F0AE) // Un verde brillante
    ),
    DockItem(
      icon: Icons.calendar_month,
      label: 'Planning',
      // Tonalità di verde 2
      activeColor: Color(0xFF00C853) // Un verde più scuro
    ),
    DockItem(
      icon: Icons.bar_chart_rounded,
      label: 'Reports',
      // Tonalità di verde 3
      activeColor: Color(0xFFB9F6CA) // Un verde pastello
    ),
    DockItem(
      icon: Icons.settings_rounded,
      label: 'Settings',
      // Tonalità di verde 4
      activeColor: Color(0xFF00E676) // Un altro verde acceso
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: widget.pages[_index],
      bottomNavigationBar: LiquidGlassDock(
        currentIndex: _index,
        // Usa 'onIndexChanged' come definito in 'liquid_glass_dock.dart'
        onIndexChanged: (i) => setState(() => _index = i),
        // 2. Passa la lista di items al widget
        items: _dockItems,
      ),
    );
  }
}
