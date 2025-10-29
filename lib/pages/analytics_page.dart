import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        elevation: 0,
        title: const Text('Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Consumer<MoneyModel>(
            builder: (context, model, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSpendingAlert(model, isDark),
                  const SizedBox(height: 24),
                  _buildGoalsSection(model, isDark),
                  const SizedBox(height: 32),
                  _buildAddNewGoal(isDark),
                  const SizedBox(height: 32),
                  _buildMonthlyBudgets(model, isDark),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingAlert(MoneyModel model, bool isDark) {
    // Calcolo reale alert basato sui dati utente
    final shoppingThisMonth = model.transactions
        .where((tx) => tx.category == 'Shopping' && 
               tx.date.month == DateTime.now().month && 
               tx.date.year == DateTime.now().year && 
               !tx.isIncome)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    
    const shoppingLimit = 600.0;
    final percentage = (shoppingThisMonth / shoppingLimit * 100).round();
    
    if (percentage < 80) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning, color: Color(0xFFF59E0B), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hai speso €${shoppingThisMonth.toStringAsFixed(2)} di €${shoppingLimit.toStringAsFixed(0)} per Shopping questo mese ($percentage%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection(MoneyModel model, bool isDark) {
    // Goals basati sui dati reali dell'utente
    final totalSavings = model.transactions
        .where((tx) => tx.isIncome)
        .fold<double>(0, (sum, tx) => sum + tx.amount) - 
        model.transactions
        .where((tx) => !tx.isIncome)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    
    final goals = [
      {
        'name': 'Fondo Emergenza',
        'current': totalSavings > 0 ? totalSavings * 0.6 : 0.0,
        'target': 5000.0,
        'icon': Icons.savings,
        'color': const Color(0xFF10B981)
      },
      {
        'name': 'Vacanze Estate',
        'current': totalSavings > 0 ? totalSavings * 0.25 : 0.0,
        'target': 2500.0,
        'icon': Icons.flight,
        'color': const Color(0xFF8B5CF6)
      },
      {
        'name': 'Nuova Auto',
        'current': totalSavings > 0 ? totalSavings * 0.15 : 0.0,
        'target': 15000.0,
        'icon': Icons.directions_car,
        'color': const Color(0xFF3B82F6)
      },
    ];

    return Column(
      children: goals.map((goal) => _buildGoalCard(goal, isDark)).toList(),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal, bool isDark) {
    final current = goal['current'] as double;
    final target = goal['target'] as double;
    final progress = target > 0 ? current / target : 0.0;
    final percentage = (progress * 100).round();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [(goal['color'] as Color).withOpacity(0.9), (goal['color'] as Color).withOpacity(0.7)],
                  ),
                ),
                child: Icon(goal['icon'] as IconData, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  goal['name'] as String,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '€${NumberFormat('#,##0.00').format(current)} / €${NumberFormat('#,##0.00').format(target)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 8,
                width: MediaQuery.of(context).size.width * 0.8 * progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [(goal['color'] as Color).withOpacity(0.9), goal['color'] as Color],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage% completato',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewGoal(bool isDark) {
    return GestureDetector(
      onTap: () {
        _showAddGoalDialog();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[100],
              ),
              child: Icon(
                Icons.add,
                size: 32,
                color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aggiungi Nuovo Obiettivo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white.withOpacity(0.8) : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBudgets(MoneyModel model, bool isDark) {
    // Budget reali basati sui dati utente
    final categories = ['Spesa', 'Shopping', 'Trasporti', 'Svago'];
    final budgetLimits = {'Spesa': 500.0, 'Shopping': 600.0, 'Trasporti': 200.0, 'Svago': 300.0};
    final icons = {'Spesa': Icons.shopping_cart, 'Shopping': Icons.shopping_bag, 'Trasporti': Icons.directions_car, 'Svago': Icons.movie};
    
    final budgets = categories.map((category) {
      final spent = model.transactions
          .where((tx) => tx.category == category && 
                 tx.date.month == DateTime.now().month && 
                 tx.date.year == DateTime.now().year && 
                 !tx.isIncome)
          .fold<double>(0, (sum, tx) => sum + tx.amount);
      
      final limit = budgetLimits[category] ?? 500.0;
      final percentage = limit > 0 ? (spent / limit * 100).round() : 0;
      
      return {
        'name': category,
        'spent': spent,
        'limit': limit,
        'icon': icons[category] ?? Icons.category,
        'percentage': percentage,
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Mensili',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        ...budgets.map((budget) => _buildBudgetItem(budget, isDark)),
      ],
    );
  }

  Widget _buildBudgetItem(Map<String, dynamic> budget, bool isDark) {
    final percentage = budget['percentage'] as int;
    final spent = budget['spent'] as double;
    final limit = budget['limit'] as double;
    final isOverBudget = percentage > 100;
    final color = isOverBudget ? const Color(0xFFEF4444) : 
                  percentage > 80 ? const Color(0xFFF59E0B) :
                  const Color(0xFF10B981);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            child: Icon(budget['icon'] as IconData, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget['name'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOverBudget 
                    ? '€${(spent - limit).toStringAsFixed(2)} oltre il budget'
                    : '€${(limit - spent).toStringAsFixed(0)} rimanenti di €${limit.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nuovo Obiettivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome obiettivo',
                prefixIcon: Icon(Icons.flag),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importo obiettivo',
                prefixIcon: Icon(Icons.euro),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementare salvataggio obiettivo
              Navigator.pop(context);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
}