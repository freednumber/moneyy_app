import 'package:flutter/material.dart';
import 'shell_scaffold.dart';
import 'pages/home_page.dart';
import 'pages/transactions_page.dart';
import 'pages/analytics_page.dart';
import 'pages/scan_receipt_page.dart';
import 'pages/profile_page.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShellScaffold(
      pages: [
        HomePage(),           // 0: Home
        TransactionsPage(),   // 1: Transactions
        AnalyticsPage(),      // 2: Analytics (Goals + Budgets)
        ScanReceiptPage(),    // 3: Scanner
        ProfilePage(),        // 4: Profile/Settings
      ],
    );
  }
}