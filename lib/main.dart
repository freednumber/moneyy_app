import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_root.dart';
import 'providers.dart';
import 'theme_provider.dart';

void main() {
  runApp(const MoneyyApp());
}

class MoneyyApp extends StatelessWidget {
  const MoneyyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoneyModel()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        title: 'Moneyy',
        debugShowCheckedModeBanner: false,
        theme: ThemeProvider.lightTheme,
        darkTheme: ThemeProvider.darkTheme,
        themeMode: ThemeMode.dark,
        home: const AppRoot(),
      ),
    );
  }
}
