import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../models.dart';
import '../providers.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Consumer<MoneyModel>(
            builder: (context, model, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPersonalHeader(isDark),
                  const SizedBox(height: 32),
                  _buildTotalBalanceCard(model, isDark),
                  const SizedBox(height: 24),
                  _buildDailyStats(model, isDark),
                  const SizedBox(height: 32),
                  _buildQuickActionsGrid(context, isDark),
                  const SizedBox(height: 32),
                  _buildRecentTransactionsSection(model, isDark),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalHeader(bool isDark) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Mario Rossi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
          ),
          child: Icon(
            Icons.notifications_outlined,
            size: 24,
            color: isDark ? Colors.white : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalBalanceCard(MoneyModel model, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [const Color(0xFF1E293B), const Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            model.format(model.netWorth),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStats(MoneyModel model, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            '↗ ${model.format(model.dailyIncome)} today',
            const Color(0xFF10B981),
            isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatChip(
            '↘ ${model.format(model.dailyExpense)} today',
            const Color(0xFFEF4444),
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildActionButton('Send', Icons.arrow_forward, isDark, () {})),
        const SizedBox(width: 16),
        Expanded(child: _buildActionButton('Request', Icons.arrow_back, isDark, () {})),
        const SizedBox(width: 16),
        Expanded(child: _buildActionButton('Top Up', Icons.credit_card, isDark, () {})),
        const SizedBox(width: 16),
        Expanded(child: _buildActionButton('More', Icons.more_horiz, isDark, () {})),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[100],
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isDark ? Colors.white : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white.withOpacity(0.8) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection(MoneyModel model, bool isDark) {
    final recent = model.recent.take(8).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recent.isEmpty)
          _buildEmptyTransactions(isDark)
        else
          ...recent.map((tx) => _buildTransactionItem(tx, model, isDark)),
      ],
    );
  }

  Widget _buildEmptyTransactions(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: isDark ? Colors.white.withOpacity(0.3) : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(MoneyTx tx, MoneyModel model, bool isDark) {
    final style = model.getTransactionStyle(tx.category);
    final dateFormat = DateFormat('MMM d');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [style.color.withOpacity(0.9), style.color.withOpacity(0.7)],
              ),
            ),
            child: Icon(style.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.category,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(tx.date),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${tx.isIncome ? '+' : '-'}${model.format(tx.amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: tx.isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}