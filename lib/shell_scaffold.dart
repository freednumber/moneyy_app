import 'package:flutter/material.dart';
import 'widgets/glass_dock.dart';

class ShellScaffold extends StatefulWidget {
  final List<Widget> pages;
  const ShellScaffold({super.key, required this.pages});

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: widget.pages[_index],
      bottomNavigationBar: GlassDock(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
