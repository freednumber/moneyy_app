import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../widgets/liquid_glass_card.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Home Page con integrazione completa del Liquid Glass Effect
/// Stile Apple WWDC 2025
class HomePageLiquidGlass extends StatelessWidget {
  const HomePageLiquidGlass({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Sfondo gradiente dinamico
          _buildAnimatedBackground(context),
          
          // Contenuto con effetto liquid glass
          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildGlassAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      _buildBalanceCard(context),
                      const SizedBox(height: 24),
                      _buildMonthlyStatsCard(context),
                      const SizedBox(height: 24),
                      _buildQuickActionsCard(context),
                      const SizedBox(height: 24),
                      _buildRecentTransactionsCard(context),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sfondo gradiente animato
  Widget _buildAnimatedBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1a1a2e),
                  const Color(0xFF16213e),
                  const Color(0xFF0f3460),
                ]
              : [
                  const Color(0xFFe3f2fd),
                  const Color(0xFFbbdefb),
                  const Color(0xFF90caf9),
                ],
        ),
      ),
    );
  }

  // App Bar con liquid glass
  Widget _buildGlassAppBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LiquidGlassContainer(
          borderRadius: 25,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          thickness: 12,
          blur: 15,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moneyy',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  Text(
                    'Gestisci le tue finanze',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
              LiquidGlassButton(
                borderRadius: 20,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                thickness: 10,
                blur: 8,
                onPressed: () {
                  // Naviga a settings
                },
                child: const Icon(Icons.settings, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card bilancio con liquid glass
  Widget _buildBalanceCard(BuildContext context) {
    return Consumer<MoneyModel>(
      builder: (context, model, child) {
        final balance = model.balance;
        final currencyFormat = NumberFormat.currency(
          symbol: model.currencySymbol,
          decimalDigits: 2,
        );

        return LiquidGlassCardWithGlow(
          borderRadius: 35,
          padding: const EdgeInsets.all(24),
          thickness: 20,
          blur: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Saldo Totale',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                currencyFormat.format(balance),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    balance >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: balance >= 0 ? Colors.greenAccent : Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    balance >= 0 ? 'In positivo' : 'In negativo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: balance >= 0
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Card statistiche mensili con liquid glass
  Widget _buildMonthlyStatsCard(BuildContext context) {
    return Consumer<MoneyModel>(
      builder: (context, model, child) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

        final monthlyIncome = model.transactions
            .where((tx) =>
                tx.amount > 0 &&
                tx.date.isAfter(monthStart) &&
                tx.date.isBefore(monthEnd))
            .fold(0.0, (sum, tx) => sum + tx.amount);

        final monthlyExpense = model.transactions
            .where((tx) =>
                tx.amount < 0 &&
                tx.date.isAfter(monthStart) &&
                tx.date.isBefore(monthEnd))
            .fold(0.0, (sum, tx) => sum + tx.amount.abs());

        final currencyFormat = NumberFormat.currency(
          symbol: model.currencySymbol,
          decimalDigits: 2,
        );

        return LiquidGlassCard(
          borderRadius: 30,
          padding: const EdgeInsets.all(20),
          thickness: 15,
          blur: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistiche ${DateFormat('MMMM yyyy', 'it_IT').format(now)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Entrate',
                      currencyFormat.format(monthlyIncome),
                      Icons.arrow_downward_rounded,
                      Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Uscite',
                      currencyFormat.format(monthlyExpense),
                      Icons.arrow_upward_rounded,
                      Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  // Card azioni rapide con liquid glass
  Widget _buildQuickActionsCard(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: 30,
      padding: const EdgeInsets.all(20),
      thickness: 15,
      blur: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Azioni Rapide',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildQuickActionButton(
                context,
                'Aggiungi',
                Icons.add_circle_outline,
                Colors.greenAccent,
                () {},
              ),
              _buildQuickActionButton(
                context,
                'Scansiona',
                Icons.qr_code_scanner,
                Colors.blueAccent,
                () {},
              ),
              _buildQuickActionButton(
                context,
                'Obiettivi',
                Icons.flag_rounded,
                Colors.orangeAccent,
                () {},
              ),
              _buildQuickActionButton(
                context,
                'Report',
                Icons.analytics_rounded,
                Colors.purpleAccent,
                () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return LiquidGlassButton(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      thickness: 10,
      blur: 6,
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  // Card transazioni recenti con liquid glass
  Widget _buildRecentTransactionsCard(BuildContext context) {
    return Consumer<MoneyModel>(
      builder: (context, model, child) {
        final recentTx = model.transactions.take(5).toList();
        final currencyFormat = NumberFormat.currency(
          symbol: model.currencySymbol,
          decimalDigits: 2,
        );

        if (recentTx.isEmpty) {
          return LiquidGlassCard(
            borderRadius: 30,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 64,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nessuna transazione',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return LiquidGlassCard(
          borderRadius: 30,
          padding: const EdgeInsets.all(20),
          thickness: 15,
          blur: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transazioni Recenti',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Vedi tutte',
                      style: TextStyle(color: Colors.blueAccent[200]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...recentTx.map((tx) => _buildTransactionItem(
                    context,
                    tx.description,
                    currencyFormat.format(tx.amount.abs()),
                    tx.amount >= 0,
                    DateFormat('dd MMM', 'it_IT').format(tx.date),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    String title,
    String amount,
    bool isIncome,
    String date,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isIncome ? Colors.greenAccent : Colors.redAccent)
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.greenAccent : Colors.redAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}$amount',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isIncome ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
