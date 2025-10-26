import 'package:flutter/material.dart';
import 'shell_scaffold.dart';
import 'pages/home_page.dart';
import 'pages/transactions_page.dart';
import 'pages/stats_page.dart';
import 'pages/scan_receipt_page.dart';
import 'pages/settings_page.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShellScaffold(
      pages: [
        HomePage(),
        TransactionsPage(),
        StatsPage(),
        ScanReceiptPage(),
        SettingsPage(),
      ],
    );
  }
}
